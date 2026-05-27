---
title: Quick start
description: This guide gets you started with gRPC in Rust with a simple working example.
weight: 10
spelling: cSpell:ignore Rust
---

### Prerequisites

- **[Rust][]**, any version supported by the current [gRPC-Rust MSRV][].

  For installation instructions, see Rust's [Getting Started][] guide.

- **Protobuf code generation tools**

  There are two tools used to generate the Rust protobuf code:

  1. **[Protocol buffer][pb] compiler**, `protoc`, [version 34.0][proto34].
     This generates the defined _message_ data structures.
  2. **gRPC-Rust plugin**, `protoc-gen-rust-grpc`
     This generates the defined _services_ and _methods_.

  There are two options for installing these tools.

  1. A C++17 compatible compiler and CMake 3.14 or higher are required to
     compile the protobuf code generation tool.
  2. Alternatively, compiled versions of the tools can be downloaded from the
     [protobuf releases] (for `protoc`) and [grpc releases] (for
     `protoc-gen-rust-grpc`) GitHub pages.
     * For this option, be sure to update your `PATH` to include both of the
       binaries.
     * For `protoc` installation instructions, see [Protocol Buffer Compiler
       Installation][pbc-install].  Note that because Rust support in `protoc`
       is not yet stable, the version installed must be exactly 34.0.

[protobuf releases]: https://github.com/protocolbuffers/protobuf/releases
[grpc releases]: https://github.com/grpc/grpc-rust/releases

### Get the example code

The example code is part of the [grpc-rust][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone -b grpc-{{< param grpc_vers.rust >}} --depth 1 https://github.com/grpc/grpc-rust
    ```

 2. Change to the `examples` directory:

    ```sh
    cd grpc-rust/examples
    ```

### Run the example

From the `examples` directory:

 1. Compile and execute the server code:

    ```sh
    cargo run --bin helloworld-server
    ```

 2. From a different terminal, compile and execute the client code to see the
    client output:

    ```sh
    cargo run --bin grpc-helloworld-client
    Greeting: Hello world
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update the gRPC service

In this section you'll update the application with an extra server method. The
gRPC service is defined using [protocol buffers][pb]. To learn more about how to
define a service in a `.proto` file see [Basics tutorial][].
For now, all you need to know is that both the
server and the client stub have a `SayHello()` RPC method that takes a
`HelloRequest` parameter from the client and returns a `HelloReply` from the
server, and that the method is defined like this:

```protobuf
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

Open `proto/helloworld/helloworld.proto` and add a new `SayHelloAgain()` method,
with the same request and response types:

```protobuf
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  // Sends another greeting
  rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

Remember to save the file!

### Regenerate gRPC code

Before you can use the new service method, you need to recompile the updated
`.proto` file.

From the `examples/` directory, run the following:

1. If you installed `protoc` and `protoc-gen-rust-grpc` into your path:

```sh
GRPC_RUST_REGENERATE_PROTO=1 cargo build --bin grpc-routeguide-client
```

2. If you prefer to build these tools from source with a C++ compiler and CMake
   as described above:

```sh
GRPC_RUST_REGENERATE_PROTO=1 cargo build --bin grpc-routeguide-client --features grpc-protobuf-build/build-plugin
```

This will regenerate the `generated.rs`, `helloworld.u.pb.rs`, and
`helloworld_grpc.pb.rs` files in `src/grpc-helloworld/generated/`, which
contain:

- Code for populating, serializing, and retrieving `HelloRequest` and
  `HelloReply` message types.
- Generated client code.

**How does this work?**

We are leveraging the `grpc-protobuf-build` crate in `examples/build.rs` to
perform the code generation step.  However, this is only executed when you are
running one of our grpc-based examples _and_ when the environment variable
`GRPC_RUST_REGENERATE_PROTO` is set.  That is, in `examples/build.rs` you will
see something like:

```rust
  if env::var_os("GRPC_RUST_REGENERATE_PROTO").is_some() {
      grpc_protobuf_build::CodeGen::new()
          .output_dir(manifest_dir.join("src/grpc-helloworld/generated"))
          .input("helloworld.proto")
          .include(manifest_dir.join("proto/helloworld"))
          .client_only()
          .compile()
          .unwrap();
  }
```

You can run `protoc` manually, instead, to perform code generation if you don't
wish to use build.rs integration.  To do that, you would use:

```sh
protoc --rust_out=src/grpc-helloworld/generated/ --rust_opt=experimental-codegen=enabled,kernel=upb \
    --rust-grpc_out=src/grpc-helloworld/generated/ --rust-grpc_opt=client_only=true \
    --proto_path=proto/helloworld/ proto/helloworld/helloworld.proto
```

### Update and run the application

You have regenerated the server and client code, but you still need to implement
and call the new method in the human-written parts of the example application.

#### Update the server

Open `src/helloworld/server.rs` (the legacy Tonic server) and add the following
function to the `impl Greeter for MyGreeter` block:

```rust
    async fn say_hello_again(
        &self,
        request: Request<HelloRequest>,
    ) -> Result<Response<HelloReply>, Status> {
        println!("Got a request from {:?}", request.remote_addr());

        let reply = hello_world::HelloReply {
            message: format!("Hello again {}!", request.into_inner().name),
        };
        Ok(Response::new(reply))
    }
```

#### Update the client

Open `src/grpc-helloworld/client.rs` to add the following code to the end of the
`main()` function body:

```rust
let response = client.say_hello_again(request).await.expect("RPC error");
println!("Greeting: {:}", response.message());
```

Remember to save your changes.

#### Run!

Run the client and server like you did before. Execute the following commands
from the `examples/` directory:

 1. Run the server:

    ```sh
    cargo run --bin helloworld-server
    ```

 2. From another terminal, run the client. This time, add a name as a
    command-line argument:

    ```sh
    cargo run --bin grpc-helloworld-client Alice
    Greeting: Hello Alice!
    Greeting: Hello again Alice!
    ```

### What's next

- Learn how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction/)
  and [Core concepts](/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial][].
- Explore the [API reference](../api).

[Rust]: https://rust-lang.org/
[Basics tutorial]: ../basics/
[gRPC-Rust MSRV]: https://github.com/grpc/grpc-rust#rust-version
[Getting Started]: https://rust-lang.org/learn/get-started/
[pb]: https://protobuf.dev/
[proto34]: https://github.com/protocolbuffers/protobuf/releases/tag/v34.0
[pbc-install]: /docs/protoc-installation/
[grpc-rust]: https://github.com/grpc/grpc-rust
[download]: https://github.com/grpc/grpc-rust/archive/grpc-{{< param grpc_vers.rust >}}.zip
[pgrg]: https://github.com/grpc/grpc-rust/tree/master/protoc-gen-rust-grpc
