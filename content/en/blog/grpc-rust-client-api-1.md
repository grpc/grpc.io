---
title: gRPC-Rust Client API Evolution (pt. 1/2)
date: 2026-05-29
spelling: cSpell:ignore Tokio
author:
  name: Doug Fawley
  position: Google
---

### PART 1

*The following is a detailed explanation of the background behind the new
gRPC-Rust client API.  It covers the process I went through while designing it,
alternatives considered, trade-offs, and advantages of the final design.  If you
are only interested in the result itself, please feel free to skip straight to
[our documentation](https://grpc.io/docs/languages/rust) instead.*

# Background: gRPC, Tonic, and Tower

[gRPC](http://grpc.io) is a high performance Remote Procedure Call (RPC)
framework. If you aren't already familiar with gRPC, please see our
[introduction](https://grpc.io/docs/what-is-grpc/introduction/).

[Tonic](https://docs.rs/tonic/latest/tonic/) is an implementation of the gRPC
protocol for the Rust programming language.  It is widely used and very popular,
with over 12k stars on github.  Tonic is designed to be part of the
[Tower](https://docs.rs/tower/latest/tower/) ecosystem, which is a framework
that attempts to unify all networking client and service APIs, allowing easy
introduction of common middleware for your application.

The gRPC-Rust project was started as an effort to bring all the advanced gRPC
features missing from Tonic to the Rust community, like integrated health
checking and retries, as well as performance-boosting strategies like zero-copy
and arena optimizations.

# Obvious Starting Point: Keep the Tonic API?

Tonic is already used by a large number of Rust users, so my initial thought was
that it would be great if we could re-use its API.  Here's a quick sample of the
current Tonic client-side API:

```rust
// Simple unary call (one request, one response):
let response = client
    .get_feature(Request::new(Point { latitude: 409146138, longitude: -746188906,}))
    .await?;

// Bidirectional streaming (many requests and responses in parallel:
let outbound = async_stream::stream! { /* request stream generator */ };
let response = client.route_chat(Request::new(outbound)).await?;
let mut inbound = response.into_inner();

while let Some(note) = inbound.message().await? { /* process responses */ }
```

When analyzing this more closely, I discovered several issues and limitations:

* **Abstraction Leak:** Tonic exposes lower-level HTTP/2 primitives (e.g.
  `GrpcService::ResponseBody` is `http_body::Body`).  gRPC applications should
  not assume that gRPC is using HTTP/2 as a transport to enable the use of other
  transports (e.g.
  [QUIC](https://github.com/grpc/proposal/blob/master/G2-http3-protocol.md)) in
  the future.
* **Unstable Dependency:** Tonic builds on `Stream` from `futures_stream` (via
  `tokio_stream)`. These crates are unstable, and we want to be able to have a
  stable release of gRPC-Rust before they are stabilized.
* **Performance Limitation:** Tonic accepts and returns owned protobuf messages.
  This means the Tonic library handles allocations, which prevents the
  application from using advanced allocation strategies like
  [arenas](https://en.wikipedia.org/wiki/Region-based_memory_management).
  Arenas are important for performance in heavily loaded, highly concurrent RPC
  systems.
* **Security Concern:** Tonic makes it easy (using the `?` operator) to
  propagate outgoing client call statuses to server responses, *including
  metadata*, which could contain secrets like tokens or other private
  information.

# What About Tower?

So we'll need to change the Tonic API, but should we keep using Tower?

In our other supported languages, gRPC directly includes many of the features
that you would get from Tower middleware, e.g.
[timeouts](https://grpc.io/docs/guides/deadlines/) and
[retries](https://grpc.io/docs/guides/retry/).  And, gRPC provides versions of
this functionality specifically designed to work well with gRPC.  In addition,
Tower was not created with streaming in mind, even though it technically works.
To implement a bidirectional stream, the `Request` and `Response` become
asynchronous objects, and the `call` method returns early in the RPC's lifecycle
to allow the application and library to interact with them.

To illustrate these problems, let's look at timeouts as an example.  The Tower
crate provides a [`timeout` module](https://docs.rs/tower/latest/tower/timeout/)
to provide this functionality.  The approach is to race the `Service` it wraps
with a timer future, dropping one when the other completes.  This works fine for
many `Service` implementations, but it does have some surprising behavior many
people are unaware of:

1. The timeout is not applied while waiting for flow control in `poll_ready`,
   meaning your call could block indefinitely.
2. The timeout only applies to the portion of the call spent waiting for the
   `Response` object to be returned from the `call` method \-- which, for
   streaming RPCs, will be almost immediately.  In gRPC, timeouts apply to the
   total time of the RPC from the moment the client starts attempting the call
   to the receipt of the final status from the server.

In addition to those behaviors which affect any `Service`, there is another
incompatibility with gRPC: we write the timeout on the wire so that the server
is aware of the client's deadline.  If an application was using the `timeout`
module, the gRPC library would never be aware of the timeout in order to
propagate it.

Another limitation of Tower is that it makes it hard for the application to
control memory allocations: the `Response` would need to be a complex type that
allows you to call into it to receive the message into a buffer.  For streaming
RPCs, something like this would be needed anyway, but for unary RPCs, which is
where arenas are most important, it would be awkward.

# Use Tower's "Style"?

If Tower is a poor fit, should we still keep the same style for calls that Tower
and Tonic users are familiar with?  I.e.

```rust
async fn call(Request) -> Response
```

We ultimately decided against this approach.  With this style, applications that
wished to do interleaved operations ("send a message, receive a message, send a
message, ...") would need to deal with the two `Request` and `Response` streams
executing concurrently and implement their own synchronization between the two
streams.

# Two APIs: Channel vs. Generated Stubs

gRPC actually provides _two different APIs_: one that the application typically
interacts with via the protobuf generated code, and one that the
[channel](https://grpc.io/docs/what-is-grpc/core-concepts/#channels) (the main
client entry point) itself implements, and that interceptors (AKA middleware)
would use.  The generated API focuses more on usability while the channel API is
a lower-level, more powerful, streaming-only design.

In Tonic, this split exists as well, but the proto generated code is just a
specialization of the Tonic API using type generics.  But this approach is not a
requirement, and in fact, there are reasons to avoid it.

With gRPC-Rust, we are taking the opportunity to incorporate some lessons
learned from our experience implementing gRPC in many other languages.  One such
idea we'd like to incorporate is to hide the details of gRPC itself from the
generated API, and only expose protobuf messages and necessary primitives.  As
an example:

```rust
// *Not* something like this:
async fn call(ctx: grpc::Context, req: MyRequestMessage, options: grpc::CallOptions)
    -> grpc::Response<MyResponseMessage>;

// More like this instead:
async fn call(req: MyRequestMessage) -> Result<MyResponseMessage, Status>;

// Example usage:
let response = client.call(request).await.expect("RPC should succeed!");
```

This is similar to gRPC-Java's design, and it allows applications to focus on
the business logic of the application: requests and responses. For other
functionality that gRPC provides \-- like accessing metadata, disabling retry,
reading peer details, etc \-- these are generally things that interceptors
should be used for, instead.

# Generated API

With that in mind, let's dive into the generated (protobuf) API in isolation
first, and understand why the nice, simple API in the example above isn't good
enough.  _(Then I'll explain how we ultimately achieved exactly that anyway\!)_

## Arenas

As mentioned earlier,
[arenas](https://en.wikipedia.org/wiki/Region-based_memory_management) are
important for making highly efficient RPC systems that can handle extremely high
QPS (Queries Per Second), by grouping related memory operations temporally and
spatially.  To allow the application to control allocations instead of the
library, we were looking for a unary API something like:

```rust
// Definition:
async fn call(req: &MyRequestMessageView, resp: &mut MyResponseMessageView) -> Status;

// Usage (with a hypothetical arena API):
let req = MyRequestMessage::new_on_arena(arena).set_id(3);
let res = MyResponseMessage::new_on_arena(arena);
client.call(&req, &mut res).expect("RPC should succeed!");
// res now contains the RPC's response
```

## Can we Make it More Usable?

That API is straightforward, but we understand that many users would not want to
pre-declare the response message type manually before making every RPC.  We can
accommodate both use cases by using the [async builder
pattern](https://doc.rust-lang.org/std/future/trait.IntoFuture.html#async-builders).
An async builder is able to return owned messages via an `IntoFuture`
implementation, while also providing an alternative method to perform the call
using a pre-allocated response.

We can also improve the ergonomics of the request message parameter.  Instead of
requiring a reference, we can accept an
[`AsView`](https://docs.rs/protobuf/4.33.5-release/protobuf/trait.AsView.html)
protobuf type that allows *either* an owned message or a view to be passed into
the call.  This is the final API we have implemented:

```rust
// Definition:
async fn call<Req>(req: Req) -> UnaryFutureBuilder<..>
where
    Req: AsView<Proxied=MyRequestMsg>;

// Implements the simple usage:
impl IntoFuture for UnaryFutureBuilder {
	type Output = Result<MyResponseMessage, StatusError>;
}

// Implements the advanced usage method:
impl UnaryFutureBuilder {
	async fn with_response_message<Res>(self, res: &mut Res) -> Status
	where
	  Res: AsMut<MutProxied = MyResponseMessage>;
}

// Usage:
fn main() {
	let request = proto!(MyRequestMessage{ id: 3 });

	// Simple Usage -- exactly what we wanted originally!:
	let response = client.call(request).await.expect("RPC should succeed!");

	// Arena usage (again with a hypothetical arena API):
	let req = MyRequestMessage::new_on_arena(arena).set_id(3);
	let res = MyResponseMessage::new_on_arena(arena);
	client.call(&req).with_response_message(&mut res).await.expect("RPC should succeed!");
}
```

We adapted these same concepts to our streaming APIs as well.  Below is an
example of the bidirectional streaming API:

```rust
// Definition:
async fn begin_stream() -> BidiCallBuilder<..>

// Implements the same async builder pattern:
impl IntoFuture for BidiCallBuilder<..> {
	type Output = (GrpcStreamingRequest, GrpcStreamingResponse);
}

// Usage:
fn main() {
	// Simple Usage:
	let (request_stream, response_stream) = client.begin_stream().await;

	request_stream.send(proto!(MyRequestMessage{..}));
	let response = response_stream.recv().await.expect("RPC should succeed!");

	// Arena usage:
	let res = MyResponseMessage::new_on_arena(arena);
	let response = response_stream.recv_into(&mut res).await.expect("RPC should succeed!");
}
```

Please see the [full documentation](https://grpc.io/docs/languages/rust) for
more detailed usage examples.

# Next Time

This covers the generated code API design process.  In Part 2 I'll go into
further details on the channel APIs.
