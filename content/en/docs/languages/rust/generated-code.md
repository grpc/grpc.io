---
title: Generated-code reference
linkTitle: Generated code
weight: 95
---

This page describes the code generated when compiling protobuf definition
(`.proto`) files with `protoc`, using the `protoc-gen-rust-grpc` [grpc
plugin](https://github.com/grpc/grpc-rust/tree/master/protoc-gen-rust-grpc).
For using protobuf messages, please see the [Protobuf Rust Generated Code
Guide](https://protobuf.dev/reference/rust/rust-generated).

You can find out how to define a gRPC service in a `.proto` file in [Service
definition](/docs/what-is-grpc/core-concepts/#service-definition).

## Generating the code

There are two main ways to generate the stubs you will use in your application:

1. Using the
   [`grpc-protobuf-build`](https://docs.rs/grpc-protobuf-build)
   crate in a [`build.rs`
   script](https://doc.rust-lang.org/cargo/reference/build-scripts.html).
2. Running the [`protoc`](https://github.com/protocolbuffers/protobuf/releases)
   binary manually with the
   [`protoc-gen-rust-grpc`](https://github.com/grpc/grpc-rust/tree/master/protoc-gen-rust-grpc)
   plugin and committing the output into revision control as needed.

Both methods require adding the following dependencies to your Rust project:
`grpc`, `protobuf`, and `grpc-protobuf`.

### Method 1: using `grpc-protobuf-build` with `build.rs`

Using this approach ensures that your generated code is always up to date as
changes are made to your proto definitions.  However, it requires anyone who
wants to compile your crate to have `protoc` installed, and the proper C++
requirements for building the `protoc-gen-rust-grpc` binary.

To implement this method, add the `grpc-protobuf-build` crate to the
`[build-dependencies]` section of your project's `Cargo.toml`.  Then, add the
following to your `build.rs`:

```rust
// Assumes /your/crate/root/ contains proto/<example>/<example>.proto
fn main() -> Result<(), Box<dyn std::error::Error>> {
    grpc_protobuf_build::CodeGen::new()
        .include("proto/<example>")
        .inputs(["<example>.proto"])
        .compile()?;
    Ok(())
}
```

Include the generated code by adding this to your application:

```rust
mod example {
    grpc::include_proto!("proto/<example>", "<example>");
}
```

For more details, please see the crate documentation for
[`grpc-protobuf-build`](https://docs.rs/grpc-protobuf-build).

### Method 2: running `protoc`

With this approach, you only generate code on demand and commit it to revision
control, reducing the dependencies on the build environment itself.  If updates
are made to the input `.proto` files, you must remember to re-run these steps.

First, ensure the `protoc-gen-rust-grpc` binary is compiled and available in
your system `PATH`.  Then run `protoc` as follows (replacing `<example>` with
your specific filenames):

```sh
# Current directory: /your/crate/root/
protoc \
   --rust_out=src/<example>/generated/ --rust_opt=experimental-codegen=enabled,kernel=upb \
   --rust-grpc_out=src/<example>/generated --rust-grpc_opt=client_only=true \
   --proto_path=proto/<example>/ \
   proto/<example>/<example>.proto
```

Include the generated code by adding this to your application:

```rust
// In src/mod.rs:
mod example {
    mod generated {
        include!("generated/generated.rs");         // Contains messages
        include!("generated/<example>_grpc.pb.rs"); // Contains grpc stubs
    }
}
```

The exact patterns you use can be customized as desired.  For example, you may
wish to include these files in a sub-module and `pub(crate)` the module
definitions.

## Methods on generated server interfaces (TBD)

The current gRPC-Rust preview does not support server-side code generation.
This will be added in a future preview version.

## Methods on generated client interfaces

For client side usage, each `service Bar` in the `.proto` file results in the
generation of a corresponding stub and a constructor: `BarClient::new(channel:
T)`, which accepts a `grpc::Channel` (or any type that implements
`grpc::client::Invoke`) and returns a `BarClient` instance.

NOTE: For each RPC method in the service, a corresponding method is generated in
the stub.  These methods utilize the [async
builder](https://doc.rust-lang.org/std/future/trait.IntoFuture.html#async-builders)
pattern to make them natural to use but also simple to configure or to invoke in
other ways for specialized use cases.

### Common Call Builder Configuration

For all four types of RPCs, the method to start the RPC returns an object that
implements `grpc_protobuf::client::CallBuilder`.  This allows configuration of
the call before it is started by `await`ing it to activate its `IntoFuture`
implementation.  An example of configuring a unary call would be:

```rust
let result = client
    .unary_call(request)
    .with_timeout(Duration::from_millis(100))  // <-- add a deadline
    .with_interceptor(interceptor)             // <-- add an interceptor
    .await;                                    // dispatch the call
```

### Unary Methods

Unary methods have the following signature on the generated client stub:

```rust
pub fn foo(&self, request: RequestMsgView) -> UnaryCallBuilder<..>
```

Note that `RequestMsgView` is actually a complex generic type that allows the
use of either owned protobuf messages or *views* of protobuf messages.  The
concept of protobuf message view types is described in some detail in the
[Protobuf Rust Generated Code
Guide](https://protobuf.dev/reference/rust/rust-generated/#message-proxy-types).

As mentioned above, the returned `UnaryCallBuilder` can be configured via the
methods on the `CallBuilder` it implements before dispatching the call.

A unary call can be dispatched in two different ways:

```rust
// Simple:
let result: Result<ResponseMsg, StatusError> = client.foo(request).await;

// Flexible:
let response = ResponseMsg::new();
let status: Status = client
    .foo(request)
    .with_response_message(&mut response) // <-- populated in place on success
    .await;
```

### Server-Streaming methods

Server-streaming methods have the following signature on the generated client
stub:

```rust
pub fn foo(&self, request: RequestMsgView) -> ServerStreamingCallBuilder<..>
```

As with unary calls, the request is passed as a complex `View` generic.
However, there is only one way to dispatch the call, which is to `.await` it.
This returns a `grpc_protobuf::client::GrpcStreamingResponse<ResponseMsg>` used
to retrieve the messages and status from the stream.

Usage example:

```rust
// Begin the call:
let response_stream: GrpcStreamingResponse<_> = client.foo(request).await;

// Process response messages:
while let Some(response: ResponseMsg) = response_stream.recv().await {
    process(response);
}
// Receive the status of the RPC:
let status: Status = response_stream.status().await;
```

### Client-Streaming methods

Client-streaming methods have the following signature on the generated client
stub:

```rust
pub fn foo(&self) -> ClientStreamingCallBuilder<..>
```

Client-streaming calls do not begin with a request message -- instead, they are
streamed to the object (a
`grpc_protobuf::client::client_streaming::ClientStreamingCall`) returned by
`.await`ing the `ClientStreamingCallBuilder`.

Usage of the `ClientStreamingCall` involves sending messages by repeatedly
calling its `send` message until it receives an error (indicating the stream
terminated) or the client has no more messages to send.  At this time, the
`close_and_recv` method should be called to receive the server's response, or
the RPC status in the event of a failure.

Usage example:

```rust
// Begin the call:
let request_stream: ClientStreamingCall<_> = client.foo().await;

// Send request messages:
while let Some(message) = get_message_to_send() {
    if request_stream.send(message).is_err() {
        // Stream terminated while sending messages.
        break;
    }
}

// Receive the response message or status of the RPC:
let result: Result<ResponseMsg, StatusError> = request_stream.close_and_recv().await;
```

### Bidirectional-Streaming methods

Bidi-streaming methods have the following signature on the generated client
stub:

```rust
pub fn foo(&self) -> BidiCallBuilder<..>
```

Bidi-streaming calls stream messages in two directions simultaneously.  To
properly express this parallelism, two objects are returned from the
`BidiCallBuilder` when it is `.await`ed: a sender and a receiver.  The client
typically interacts with these objects in separate tasks.  Like client-streaming
calls, if an error is encountered while sending a request, the client should
stop sending and discover the result of the RPC (which could be a success) using
the receiver.

Usage example:

```rust
// Begin the call:
let (mut tx, mut rx) = client.foo().await;

// Spawn a task for sending requests:
let handle = tokio::task::spawn(async move {
    while let Some(message) = get_message_to_send() {
        if tx.send(message).is_err() {
            // Stream terminated while sending messages.
            return;
        }
    }
    // Explicitly signal the client is done sending; note that this
    // happens implicitly when tx is dropped.
    tx.close();
});

// In parallel with the task above, receive responses:
while let Some(response: ResponseMsg) = rx.recv().await {
    // Process "response"
}

// Receive the final status of the RPC:
let status: Status = rx.status().await;
```
