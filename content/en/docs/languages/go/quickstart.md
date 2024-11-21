---
title: Quick start
description: This guide gets you started with gRPC in Go with a simple working example.
weight: 10
spelling: cSpell:ignore Fatalf GOPATH
---

### Prerequisites

- **[Go][]**, any one of the **two latest major** [releases of Go][].

  For installation instructions, see Go's [Getting Started][] guide.

- **[Protocol buffer][pb] compiler**, `protoc`, [version 3][proto3].

  For installation instructions, see [Protocol Buffer Compiler
  Installation][pbc-install].

- **Go plugins** for the protocol compiler:

   1. Install the protocol compiler plugins for Go using the following commands:

      ```sh
      go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
      go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
      ```

   2. Update your `PATH` so that the `protoc` compiler can find the plugins:

      ```sh
      export PATH="$PATH:$(go env GOPATH)/bin"
      ```

### Get the example code

The example code is part of the [grpc-go][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone -b {{< param grpc_vers.go >}} --depth 1 https://github.com/grpc/grpc-go
    ```

 2. Change to the quick start example directory:

    ```sh
    cd grpc-go/examples/helloworld
    ```

### Run the example

From the `examples/helloworld` directory:

 1. Compile and execute the server code:

    ```sh
    go run greeter_server/main.go
    ```

 2. From a different terminal, compile and execute the client code to see the
    client output:

    ```sh
    go run greeter_client/main.go
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

Open `helloworld/helloworld.proto` and add a new `SayHelloAgain()` method, with
the same request and response types:

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

While still in the `examples/helloworld` directory, run the following command:

```sh
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    helloworld/helloworld.proto
```

This will regenerate the `helloworld/helloworld.pb.go` and  `helloworld/helloworld_grpc.pb.go` files, which contain:

- Code for populating, serializing, and retrieving `HelloRequest` and
  `HelloReply` message types.
- Generated client and server code.

### Update and run the application

You have regenerated server and client code, but you still need to implement
and call the new method in the human-written parts of the example application.

#### Update the server

Open `greeter_server/main.go` and add the following function to it:

```go
func (s *server) SayHelloAgain(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
        return &pb.HelloReply{Message: "Hello again " + in.GetName()}, nil
}
```

#### Update the client

Open `greeter_client/main.go` to add the following code to the end of the
`main()` function body:

```go
r, err = c.SayHelloAgain(ctx, &pb.HelloRequest{Name: *name})
if err != nil {
        log.Fatalf("could not greet: %v", err)
}
log.Printf("Greeting: %s", r.GetMessage())
```

Remember to save your changes.

#### Run!

Run the client and server like you did before. Execute the following commands
from the `examples/helloworld` directory:

 1. Run the server:

    ```sh
    go run greeter_server/main.go
    ```

 2. From another terminal, run the client. This time, add a name as a
    command-line argument:

    ```sh
    go run greeter_client/main.go --name=Alice
    ```

    You'll see the following output:

    ```sh
    Greeting: Hello Alice
    Greeting: Hello again Alice
    ```

### What's next

- Learn how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction/)
  and [Core concepts](/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial][].
- Explore the [API reference](../api).

[Basics tutorial]: ../basics/
[download]: https://github.com/grpc/grpc-go/archive/{{< param grpc_vers.go >}}.zip
[Getting Started]: https://golang.org/doc/install
[Go]: https://golang.org
[grpc-go]: https://github.com/grpc/grpc-go
[pb]: https://developers.google.com/protocol-buffers
[proto3]: https://protobuf.dev/programming-guides/proto3
[pbc-install]: /docs/protoc-installation/
[releases of Go]: https://golang.org/doc/devel/release.html
