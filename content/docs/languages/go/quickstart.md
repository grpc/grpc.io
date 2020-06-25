---
title: Quick Start
description: This guide gets you started with gRPC in Go with a simple working example.
weight: 10
---

### Prerequisites

- **[Go][]**, any one of the **three latest major** [releases of Go][].

  For installation instructions, see Go's [Getting Started][] guide.

- **[Protocol buffer][pb] compiler**, `protoc`, [version 3][proto3].

  For installation instructions, see [Protocol Buffer Compiler
  Installation][pbc-install].

- **Go plugin** for the protocol compiler:

   1. Install the protocol compiler plugin for Go (`protoc-gen-go`) using the
      following command:

      ```sh
      $ export GO111MODULE=on  # Enable module mode
      $ go get github.com/golang/protobuf/protoc-gen-go
      ```

   2. Update your `PATH` so that the `protoc` compiler can find the plugin:

      ```sh
      $ export PATH="$PATH:$(go env GOPATH)/bin"
      ```

### Get the example code

The example code is part of the [grpc-go][] repo.

 1. [Dowload the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    $ git clone -b {{< param grpc_go_release_tag >}} https://github.com/grpc/grpc-go
    ```

 2. Change to the quick start example directory:

    ```sh
    $ cd grpc-go/examples/helloworld
    ```

### Run the example

From the `examples/helloworld` directory:

 1. Compile and execute the server code:

    ```sh
    $ go run greeter_server/main.go
    ```

 2. From a different terminal, compile and execute the client code to see the
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
`.proto` file.

While still in the `examples/helloworld` directory, run the following commands:

```sh
$ ( cd ../../cmd/protoc-gen-go-grpc && go install . )
$ protoc \
  --go_out=Mgrpc/service_config/service_config.proto=/internal/proto/grpc_service_config:. \
  --go-grpc_out=Mgrpc/service_config/service_config.proto=/internal/proto/grpc_service_config,requireUnimplementedServers=false:. \
  --go_opt=paths=source_relative \
  --go-grpc_opt=paths=source_relative \
  helloworld/helloworld.proto
```

This will regenerate the `helloworld/helloworld.pb.go` and  `helloworld/helloworld_grpc.pb.go` files, which contain:

- Code for populating, serializing, and retrieving `HelloRequest` and
  `HelloReply` message types.
- Generated client and server code.

{{< note >}}
  We are in the process of transitioning to a [new Go protoc plugin][#3453].
  Until the transition is complete, you need to install
  `grpc-go/cmd/protoc-gen-go-grpc` manually before regenerating `.pb.go` files.
  To track progress on this issue, see [Update Go quick start #298][#298].

  [#298]: https://github.com/grpc/grpc.io/issues/298
  [#3453]: https://github.com/grpc/grpc-go/pull/3453
{{< /note >}}

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

- Read a full explanation of how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction)
  and [gRPC Concepts](/docs/guides/concepts/).
- Work through a more detailed tutorial in [gRPC Basics: Go](/docs/tutorials/basic/go/).
- Explore the gRPC Go core API in its [reference
  documentation](https://godoc.org/google.golang.org/grpc).

[download]: https://github.com/grpc/grpc-go/archive/{{< param grpc_go_release_tag >}}.zip
[Getting Started]: https://golang.org/doc/install
[Go]: https://golang.org
[grpc-go]: https://github.com/grpc/grpc-go
[pb]: https://developers.google.com/protocol-buffers
[proto3]: https://developers.google.com/protocol-buffers/docs/proto3
[pbc-install]: /docs/protoc-installation
[releases of Go]: https://golang.org/doc/devel/release.html
