---
title: Go Quick Start
layout: quickstart
short: Go
description: This guide gets you started with gRPC in Go with a simple working example.
---

### Prerequisites

- **Go** version 1.9+. For installation instructions, see Go's [Getting
  Started](https://golang.org/doc/install) guide.

#### gRPC

Use the following command to install gRPC.

```sh
$ go get -u google.golang.org/grpc
```

#### Protocol Buffers

While not mandatory, gRPC applications usually leverage [Protocol Buffers][pb]
for service definitions and data serialization, and the example code uses
[proto3][].

 1. Install the `protoc` compiler:

    - macOS:

      ```sh
      $ brew install protobuf
      ```

    - Any OS:

      1. Download a zip file of the latest version of pre-compiled binaries for
          your operating system from [github.com/google/protobuf/releases][]
          (`protoc-<version>-<os>.zip`).
      2. Unzip the file.
      3. Update your environment's path variable to include the path to the
          `protoc` executable.

 2. Install the `protoc` plugin for Go

    ```sh
    $ go get -u github.com/golang/protobuf/protoc-gen-go
    ```

 3. Update your `PATH` so that the `protoc` compiler can find the plugin:

    ```sh
    $ export PATH="$PATH:$(go env GOPATH)/bin"
    ```

### Run the example

The grpc sources that you fetched in a previous step also contain the example
code.

 1. Change to the example's directory:

    ```sh
    $ cd $(go env GOPATH)/src/google.golang.org/grpc/examples/helloworld
    ```

 2. Compile and execute the server code:

    ```sh
    $ go run greeter_server/main.go
    ```

 3. From a different terminal, compile and execute the client code to see the
    client output:

    ```sh
    $ go run greeter_client/main.go
    Greeting: Hello world
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update a gRPC service

In this section you'll update the application with an extra server method. The
gRPC service is defined using [protocol buffers][pb]. To learn more about how to
define a service in a `.proto` file see [gRPC Basics:
Go](/docs/tutorials/basic/go). For now, all you need to know is that both the
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

Edit `helloworld/helloworld.proto` and add a new `SayHelloAgain()` method, with
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
proto file.

From the `examples/helloworld` directory, run the following command:

```sh
$ protoc -I helloworld/ helloworld/helloworld.proto --go_out=plugins=grpc:helloworld
```

This will regenerate the `helloworld/helloworld.pb.go` file, which contains:

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
r, err = c.SayHelloAgain(ctx, &pb.HelloRequest{Name: name})
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
    $ go run greeter_server/main.go
    ```

 2. From another terminal, run the client. This time, add a name as a
    command-line argument:

    ```sh
    $ go run greeter_client/main.go Alice
    ```

    You'll see the following output:

    ```sh
    Greeting: Hello Alice
    Greeting: Hello again Alice
    ```

### What's next

- Read a full explanation of how gRPC works in [What is gRPC?](/docs/guides/)
  and [gRPC Concepts](/docs/guides/concepts/).
- Work through a more detailed tutorial in [gRPC Basics: Go](/docs/tutorials/basic/go/).
- Explore the gRPC Go core API in its [reference
  documentation](https://godoc.org/google.golang.org/grpc).

[github.com/google/protobuf/releases]: https://github.com/google/protobuf/releases
[pb]: https://developers.google.com/protocol-buffers
[proto3]: https://developers.google.com/protocol-buffers/docs/proto3
