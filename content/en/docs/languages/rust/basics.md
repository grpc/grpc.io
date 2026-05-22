---
title: Basics tutorial
description: A basic tutorial introduction to gRPC in Rust.
weight: 50
spelling: cSpell:ignore struct
---

This tutorial provides a basic Rust programmer's introduction to working with
gRPC.

By walking through this example you'll learn how to:

- Define a service in a `.proto` file.
- Generate client code using the protocol buffer compiler.
- Use the Rust gRPC API to write a simple client for your service.

It assumes that you have read the [Introduction to
gRPC](/docs/what-is-grpc/introduction/) and are familiar with [protocol
buffers](https://protobuf.dev/overview).  Note that the example in this tutorial
uses the proto3 version of the protocol buffers language: you can find out more
in the [proto3 language guide](https://protobuf.dev/programming-guides/proto3)
and the [Rust generated code
guide](https://protobuf.dev/reference/rust/rust-generated).  Note that
protobuf-Rust is also still in a preview state and their APIs may be unstable.

> NOTE: server-side support is not yet available in this version of grpc-Rust.
> This guide will be updated when it is.

### Why use gRPC?

{{< why-grpc >}}

### Setup

You should have already installed the tools needed to generate client and server
interface code -- if you haven't, see the [Prerequisites][] section of [Quick
start][] for setup instructions.

### Get the example code

The example code is part of the [grpc-rust][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone -b {{< param grpc_vers.rust >}} --depth 1 https://github.com/grpc/grpc-rust
    ```

 2. Change to the examples directory:

    ```sh
    cd grpc-rust/examples
    ```

### Defining the service

Our first step (as you'll know from the [Introduction to
gRPC](/docs/what-is-grpc/introduction/)) is to define the gRPC *service* and the
method *request* and *response* types using [protocol
buffers](https://protobuf.dev/overview).  For the complete `.proto` file, see
[routeguide/route_guide.proto](https://github.com/grpc/grpc-rust/blob/master/examples/proto/routeguide/route_guide.proto).

To define a service, you specify a named `service` in your `.proto` file:

```proto
service RouteGuide {
   ...
}
```

Then you define `rpc` methods inside your service definition, specifying their
request and response types. gRPC lets you define four kinds of service method,
all of which are used in the `RouteGuide` service:

- A *simple RPC* where the client sends a request to the server using the stub
  and waits for a response to come back, just like a normal function call.

  ```proto
  // Obtains the feature at a given position.
  rpc GetFeature(Point) returns (Feature) {}
  ```

- A *server-side streaming RPC* where the client sends a request to the server
  and gets a stream to read a sequence of messages back. The client reads from
  the returned stream until there are no more messages. As you can see in our
  example, you specify a server-side streaming method by placing the `stream`
  keyword before the *response* type.

  ```proto
  // Obtains the Features available within the given Rectangle.  Results are
  // streamed rather than returned at once (e.g. in a response message with a
  // repeated field), as the rectangle may cover a large area and contain a
  // huge number of features.
  rpc ListFeatures(Rectangle) returns (stream Feature) {}
  ```

- A *client-side streaming RPC* where the client writes a sequence of messages
  and sends them to the server, again using a provided stream. Once the client
  has finished writing the messages, it waits for the server to read them all
  and return its response. You specify a client-side streaming method by placing
  the `stream` keyword before the *request* type.

  ```proto
  // Accepts a stream of Points on a route being traversed, returning a
  // RouteSummary when traversal is completed.
  rpc RecordRoute(stream Point) returns (RouteSummary) {}
  ```

- A *bidirectional streaming RPC* where both sides send a sequence of messages
  using a read-write stream. The two streams operate independently, so clients
  and servers can read and write in whatever order they like: for example, the
  server could wait to receive all the client messages before writing its
  responses, or it could alternately read a message then write a message, or
  some other combination of reads and writes. The order of messages in each
  stream is preserved. You specify this type of method by placing the `stream`
  keyword before both the request and the response.

  ```proto
  // Accepts a stream of RouteNotes sent while a route is being traversed,
  // while receiving other RouteNotes (e.g. from other users).
  rpc RouteChat(stream RouteNote) returns (stream RouteNote) {}
  ```

Our `.proto` file also contains protocol buffer message type definitions for all
the request and response types used in our service methods - for example, here's
the `Point` message type:

```proto
// Points are represented as latitude-longitude pairs in the E7 representation
// (degrees multiplied by 10**7 and rounded to the nearest integer).
// Latitudes should be in the range +/- 90 degrees and longitude should be in
// the range +/- 180 degrees (inclusive).
message Point {
  int32 latitude = 1;
  int32 longitude = 2;
}
```

### Generating client code

Next we need to generate the gRPC client code from our `.proto` service
definition. We do this using the protocol buffer compiler `protoc` with a
special gRPC Rust plugin. This is similar to what we did in the [Quick start][].

From the `examples/` directory, run the following command:

```sh
protoc \
   --rust_out=src/grpc-routeguide/generated/ --rust_opt=experimental-codegen=enabled,kernel=upb \
   --rust-grpc_out=src/grpc-routeguide/generated/ --rust-grpc_opt=client_only=true \
   --proto_path=proto/routeguide/ \
   proto/routeguide/route_guide.proto
```

Running this command generates the following files in the
[routeguide](https://github.com/grpc/grpc-rust/blob/master/examples/src/grpc-routeguide/generated) directory:

- `route_guide.u.pb.rs`, which contains all the protocol buffer code to
  populate, serialize, and retrieve request and response message types.
- `route_guide_grpc.pb.rs`, which contains a wrapper type (or *stub*) for
  clients to call with the methods defined in the `RouteGuide` service.
- `generated.rs`, a helper for the protobuf message generated code.

### Including the generated code in your application

To include this generated code in our application, add the following to your
crate (often in the top-level mod.rs or lib.rs):

```rust
mod generated {
    pub mod routeguide {
        include!("generated/generated.rs"); // Contains messages
        include!("generated/route_guide_grpc.pb.rs"); // Contains grpc stubs
    }
}
```

### Creating the client {#client}

In this section, we'll look at creating a Rust client for our `RouteGuide`
service. You can see our complete example client code in
[grpc-rust/examples/src/grpc-routeguide/client.rs](https://github.com/grpc/grpc-rust/master/tree/examples/src/grpc-routeguide/client.rs).

#### Creating a stub

To call service methods, we first need to create a gRPC *channel* to communicate
with the server. We create this by passing the server address and port number to
`Channel::new()` as follows:

```rust
use grpc::client::Channel;

let channel = Channel::new(
    format!("dns:///{address}"),
    Arc::new(LocalChannelCredentials::new()),
    ChannelOptions::default(),
);
```

You can substitute the `LocalChannelCredentials` with another credentials
implementation (for example, TLS, GCE credentials, or JWT credentials) when a
service requires them. The `RouteGuide` service doesn't require any credentials.
"Local" credentials is a safe plaintext credential type that verifies it is
connecting to a local address, or fails to establish the connection.  You should
always have a strong credential type when connecting to any remote peer.

Once the gRPC *channel* is set up, we need a client *stub* to perform RPCs. We
get it using the `RouteGuideClient::new` method provided by the code generated
from the example `.proto` file.

```rust
use crate::generated::routeguide::route_guide_client::RouteGuideClient;

let client = RouteGuideClient::new(channel);
```

#### Calling service methods

Now let's look at how we call our service methods. Note that in gRPC-Rust, all
RPCs and their operations are implemented with async functions, which means that
you will typically `.await` them to wait for them to complete.

##### Simple RPC

Calling the simple RPC `GetFeature` is just like calling a local async method.

```rust
let feature = client
    .get_feature(proto!(Point{latitude: 409146138, longitude: -746188906}))
    .await?; // Optional: use `.map_err()` to transform errors before propagating.
```

As you can see, we call the method on the stub we got earlier. In our method
parameter we create and populate a request protocol buffer object (in our case
`Point`).  If the call doesn't return an error, then `feature` will be the
response information from the server.

```rust
// This is sufficient to print feature's "debug" information but we implement
// prettier output in the example application.
println!("{feature:?}");
```

##### Server-side streaming RPC

Here's where we call the server-side streaming method `ListFeatures`, which
returns a stream of geographical `Feature`s.

```rust
// Initialize a Rectangle:
let rect = proto!(Rectangle{...});

// Start the RPC.
let mut response_stream = client.list_features(rect).await;

// Receive the response messages.
while let Some(feature) = response_stream.recv().await {
    print_feature(feature);
}

// Confirm the status.
let status = response_stream.status().await;
assert!(status.is_ok(), "{status:?}");
```

As in the simple RPC, we pass the method the request. However, instead of
getting a response object back, we get back an instance of
`GrpcStreamingResponse<Feature>`.  We use the `GrpcStreamingResponse`'s `recv()`
method to repeatedly read in the server's responses to a response protocol
buffer object (in this case a `Feature`) until there are no more messages, i.e.
until `None` is returned.  At that time, the client needs to check the status
returned by the `status()` method.  If it is `.ok()`, the RPC succeeded;
otherwise it will contain the failure information.

##### Client-side streaming RPC

The client-side streaming method `RecordRoute` is similar to the server-side
method, except that we pass no parameters to the method and get a
`ClientStreamingCall` back, which we can use to both write messages *and* read
the final response message or the status if an error occurred.

```rust
// Create a random number of random points.
let point_count = rand::random_range(2..=30); // Traverse at least two points
let mut points = Vec::with_capacity(point_count);
for _ in 0..point_count {
    points.push(random_point());
}
println!("Traversing {point_count} points.");

// Start the RPC.
let mut stream = client.record_route().await;

// Send the request messages.
for point in points {
    if stream.send(&point).await.is_err() {
        // RPC terminated early; abort sending and the response stream
        // will provide the RPC status.
        break;
    }
}

// Receive the response or status.
let response = stream.close_and_recv().await.expect("RPC failed");
println!(
    "Route summary: Point count: {}, Distance: {}",
    response.point_count(),
    response.distance()
);
```

The `ClientStreamingCall` has a `send()` method that we can use to send requests
to the server. Once we've finished writing our client's requests to the stream
using `send()`, we need to call `close_and_recv()` on the stream to let gRPC
know that we've finished writing and are expecting to receive a response.  We
get our response message or the RPC status from that operation.

##### Bidirectional streaming RPC

Finally, let's look at our bidirectional streaming RPC `RouteChat()`. As in the
case of `RecordRoute`, we pass no parameters to the method when we call it.
This time, however, we receive two streaming objects, `GrpcStreamingRequest` and
`GrpcStreamingResponse`, that we can use to write and read messages,
respectively. This allows us to send values via our method's stream while the
server is still sending messages to *their* message stream.

```rust
// Start the RPC.
let (mut tx, mut rx) = client.route_chat().await;

// Spawn a task to send the request messages asynchronously.
let handle = tokio::task::spawn(async move {
    for note in notes {
        if tx.send(note).await.is_err() {
            // RPC terminated early; abort sending and the response stream
            // will provide the RPC status.
            return;
        }
    }
    // Indicate to the server that we are done sending requests.  This also
    // triggers naturally if `tx` is dropped, which will happen automatically
    // at the end of this task.
    tx.close();
});

// Receive the response messages in the current task.
while let Some(response) = rx.recv().await {
    println!(
        "Got message {} at Point: {{{}, {}}}",
        response.message(),
        response.location().latitude(),
        response.location().longitude()
    );
}

// Confirm the status.
let status = rx.status().await;
assert!(status.is_ok(), "{status:?}");

// Wait for the spawned task to complete as part of proper resource cleanup.
handle.await.unwrap();
```

The syntax for reading and writing here is very similar to our client-side and
server-side streaming methods, except we use the `GrpcStreamingRequest`'s
`close()` method once we've finished our call.  Note that this happens
automatically via its `Drop` implementation as well.  Although each side will
always get the other's messages in the order they were written, both the client
and server can read and write in any order — the streams operate completely
independently.

### Try it out!

Execute the following commands from the `examples/route_guide` directory:

 1. Run the tonic routeguide server:

    ```sh
    cargo run --bin routeguide-server
    ```

 2. From another terminal, run the client:

    ```sh
    cargo run --bin grpc-routeguide-client
    ```

You'll see output like this:

```nocode
Connecting to [::1]:10000...
*** SIMPLE RPC ***
Response = Name = "Berkshire Valley Management Area Trail, Jefferson, NJ, USA", Point: {409146138, -746188906}
*** MISSING FEATURE ***
Response = Name = "", Point: {0, 0}
*** FEATURES IN RANGE ***
Response = Name = "Patriots Path, Mendham, NJ 07945, USA", Point: {407838351, -746143763}
Response = Name = "101 New Jersey 10, Whippany, NJ 07981, USA", Point: {408122808, -743999179}
...
*** RECORD ROUTE ***
Traversing 29 points.
Route summary: Point count: 29, Distance: 313071718
*** ROUTE CHAT ***
Got message Message One at Point: {0, 1}
Got message Message Two at Point: {0, 2}
Got message Message Three at Point: {0, 3}
Got message Message One at Point: {0, 1}
Got message Message Four at Point: {0, 1}
Got message Message One at Point: {0, 1}
Got message Message Four at Point: {0, 1}
Got message Message Five at Point: {0, 1}
```

[download]: https://github.com/grpc/grpc-rust/archive/{{< param grpc_vers.rust >}}.zip
[grpc-rust]: https://github.com/grpc/grpc-rust
[Prerequisites]: ../quickstart/#prerequisites
[Quick start]: ../quickstart/
