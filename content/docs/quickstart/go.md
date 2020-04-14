---
title: Go Quick Start
layout: quickstart
short: Go
description: This guide gets you started with gRPC in Go with a simple working example.
protoc-version: 3.11.4
---

<style type="text/css">
    ol ol { list-style-type: lower-alpha !important; }
</style>

### Prerequisites

- **[Go][]**, any one of the **three latest major** [releases of Go][]. For
  installation instructions, see Go's [Getting Started][] guide.

#### gRPC

Use the following command to install gRPC as a [module][]:

```sh
$ export GO111MODULE=on # Enable module-aware mode
$ go get google.golang.org/grpc@{{< param grpc_release_tag >}}
```

#### Protocol Buffers

While not mandatory, gRPC applications usually leverage [Protocol Buffers][pb]
for service definitions and data serialization, and the example code uses
[proto3][].

 1. Install the `protoc` compiler:

     1. Download a zip file of the latest version of pre-compiled binaries for
        your operating system from [github.com/google/protobuf/releases][]
        (`protoc-<version>-<os><arch>.zip`). For example:

        ```sh
        $ PB_REL="https://github.com/protocolbuffers/protobuf/releases"
        $ curl -LO $PB_REL/download/v{{< param protoc-version >}}/protoc-{{< param protoc-version >}}-linux-x86_64.zip
        ```

     2. Unzip the file under `$HOME/.local` or a directory of your choice. For
        example:

        ```sh
        $ unzip protoc-{{< param protoc-version >}}-linux-x86_64.zip -d $HOME/.local
        ```

     3. Update your environment's path variable to include the path to the
        `protoc` executable. For example:

        ```sh
        $ export PATH="$PATH:$HOME/.local/bin"
        ```

    > **MacOS note**: Using [Homebrew][]? Simply run: `brew install protobuf`.

 2. The `protoc` plugin for Go (`protoc-gen-go`) was installed as a dependency
    of the `grpc` module. You can confirm this, or install the plugin, using the
    following command:

    ```sh
    $ go get github.com/golang/protobuf/protoc-gen-go
    ```

 3. Update your `PATH` so that the `protoc` compiler can find the plugin:

    ```sh
    $ export PATH="$PATH:$(go env GOPATH)/bin"
    ```

### Copy the example

The example code is part of the `grpc` source, which you fetched by following
steps of the previous section. You'll need a local copy of the example code to
work through this quick start.

 1. Choose a suitable working directory, and ensure that it exists:

     ```sh
    $ export MY_EXAMPLES="$HOME/examples"
    $ mkdir -p "$MY_EXAMPLES"
    ```

 2. Copy the example source:

    ```sh
    $ EX_SRC_DIR="$(go env GOPATH)/pkg/mod/google.golang.org/grpc@{{< param grpc_release_tag >}}/examples"
    $ cp -R "$EX_SRC_DIR/helloworld" "$MY_EXAMPLES"
    ```

 3. Ensure that the example files are writable since you'll be making changes soon:

    ```sh
    $ chmod -R u+w "$MY_EXAMPLES/helloworld"
    ```

 4. Change to the example's directory:

    ```sh
    $ cd "$MY_EXAMPLES/helloworld"
    ```

 5. Setup the example as a module:

    ```sh
    $ go mod init examples/helloworld
    ```

 6. Adjust import paths to reference local packages (rather than those from the
    original `google.golang.org/grpc` module):

    ```sh
    $ perl -pi -e 's|google.golang.org/grpc/||g' greeter_{client,server}/main.go
    ```

### Run the example

From the `$MY_EXAMPLES/helloworld` directory:

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
proto file.

From the `$MY_EXAMPLES/helloworld` directory, run the following command:

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
[Getting Started]: https://golang.org/doc/install
[Go]: https://golang.org
[Homebrew]: https://brew.sh
[module]: https://github.com/golang/go/wiki/Modules
[pb]: https://developers.google.com/protocol-buffers
[proto3]: https://developers.google.com/protocol-buffers/docs/proto3
[releases of Go]: https://golang.org/doc/devel/release.html
