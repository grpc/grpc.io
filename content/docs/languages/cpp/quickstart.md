---
title: Quick start
description: This guide gets you started with gRPC in C++ with a simple working example.
weight: 10
spelling: cSpell:ignore autoconf automake cmake cout DCMAKE endl libtool mkdir popd pushd
cmake-version: 3.17.0
---

In the C++ world, there's no universally accepted standard for managing project
dependencies. In this quick start, you'll follow steps to build and locally
install gRPC before building and running this quick start's Hello World example.

### Setup

Choose a directory to hold locally installed packages. This page assumes that
the environment variable `MY_INSTALL_DIR` holds this directory path. For
example:

```sh
$ export MY_INSTALL_DIR=$HOME/.local
```

Ensure that the directory exists:

```sh
$ mkdir -p $MY_INSTALL_DIR
```

Add the local `bin` folder to your path variable, for example:

```sh
$ export PATH="$PATH:$MY_INSTALL_DIR/bin"
```

### Prerequisites

#### cmake

Version 3.13 or later of `cmake` is required to install gRPC locally.

- Linux

  ```sh
  $ sudo apt install -y cmake
  ```

- macOS:

  ```sh
  $ brew install cmake
  ```

- For general `cmake` installation instructions, see [Installing CMake][].

Check the version of `cmake`:

```sh
$ cmake --version
```

Under Linux, the version of the system-wide `cmake` can be too low. You can
install a more recent version into your local installation directory as follows:

```sh
$ wget -q -O cmake-linux.sh https://github.com/Kitware/CMake/releases/download/v{{< param cmake-version >}}/cmake-{{< param cmake-version >}}-Linux-x86_64.sh
$ sh cmake-linux.sh -- --skip-license --prefix=$MY_INSTALL_DIR
$ rm cmake-linux.sh
```

#### gRPC and Protocol Buffers

While not mandatory, gRPC applications usually leverage [Protocol Buffers][pb]
for service definitions and data serialization, and the example code uses
[proto3][].

The following instructions will locally install gRPC and Protocol Buffers.

1.  Install the basic tools required to build gRPC:

    - Linux

      ```sh
      $ sudo apt install -y build-essential autoconf libtool pkg-config
      ```

    - macOS:

      ```sh
      $ brew install autoconf automake libtool pkg-config
      ```

2.  Clone the `grpc` repo and its submodules:

    ```sh
    $ git clone --recurse-submodules -b {{< param grpc_vers.core >}} https://github.com/grpc/grpc
    $ cd grpc
    ```

3.  Build and locally install gRPC and all requisite tools:

    ```sh
    $ mkdir -p cmake/build
    $ pushd cmake/build
    $ cmake -DgRPC_INSTALL=ON \
          -DgRPC_BUILD_TESTS=OFF \
          -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR \
          ../..
    $ make -j
    $ make install
    $ popd
    ```

More information:

- You can find a complete set of instructions for building gRPC C++ in [Building
  from source][from-source].
- For general instructions on how to add gRPC as a dependency to your C++
  project, see [Start using gRPC C++][using-grpc].

[from-source]: https://github.com/grpc/grpc/blob/master/BUILDING.md
[using-grpc]: https://github.com/grpc/grpc/tree/master/src/cpp#to-start-using-grpc-c

### Build the example

The example code is part of the `grpc` repo source, which you cloned as part of
the steps of the previous section.

1.  Change to the example's directory:

    ```sh
    $ cd examples/cpp/helloworld
    ```

2.  Build the example using `cmake`:

    ```sh
    $ mkdir -p cmake/build
    $ pushd cmake/build
    $ cmake -DCMAKE_PREFIX_PATH=$MY_INSTALL_DIR ../..
    $ make -j
    ```

    {{< alert title="Note" color="info" >}}
    **Getting build failures?** Most issues, at this point, are a result of a
    faulty installation. Ensure that the have the right versions of `cmake`, and
    carefully recheck your installation.
    {{< /alert >}}

### Try it!

Run the example from the example **build** directory
`examples/cpp/helloworld/cmake/build`:

1.  Run the server:

    ```sh
    $ ./greeter_server
    ```

1.  From a different terminal, run the client and see the client output:

    ```sh
    $ ./greeter_client
    Greeter received: Hello world
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update the gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [Introduction to gRPC](/docs/what-is-grpc/introduction/) and [Basics
tutorial](../basics/). For now all you need to know is that both the
server and the client stub have a `SayHello()` RPC method that takes a
`HelloRequest` parameter from the client and returns a `HelloResponse` from the
server, and that this method is defined like this:

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

Open [examples/protos/helloworld.proto][] and add a new `SayHelloAgain()` method, with the
same request and response types:

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

From the example **build** directory `examples/cpp/helloworld/cmake/build`, run:

```sh
$ make -j
```

This regenerates `helloworld.pb.{h,cc}` and `helloworld.grpc.pb.{h,cc}`, which
contains the generated client and server classes, as well as classes for
populating, serializing, and retrieving our request and response types.

### Update and run the application

You have new generated server and client code, but you still need to implement
and call the new method in the human-written parts of our example application.

#### Update the server

Open `greeter_server.cc` from the example's root directory. Implement the new
method like this:

```c++
class GreeterServiceImpl final : public Greeter::Service {
  Status SayHello(ServerContext* context, const HelloRequest* request,
                  HelloReply* reply) override {
     // ...
  }

  Status SayHelloAgain(ServerContext* context, const HelloRequest* request,
                       HelloReply* reply) override {
    std::string prefix("Hello again ");
    reply->set_message(prefix + request->name());
    return Status::OK;
  }
};

```

#### Update the client

A new `SayHelloAgain()` method is now available in the stub. We'll follow the
same pattern as for the already present `SayHello()` and add a new
`SayHelloAgain()` method to `GreeterClient`:

```c++
class GreeterClient {
 public:
  // ...
  std::string SayHello(const std::string& user) {
     // ...
  }

  std::string SayHelloAgain(const std::string& user) {
    // Follows the same pattern as SayHello.
    HelloRequest request;
    request.set_name(user);
    HelloReply reply;
    ClientContext context;

    // Here we can use the stub's newly available method we just added.
    Status status = stub_->SayHelloAgain(&context, request, &reply);
    if (status.ok()) {
      return reply.message();
    } else {
      std::cout << status.error_code() << ": " << status.error_message()
                << std::endl;
      return "RPC failed";
    }
  }
```

Finally, invoke this new method in `main()`:

```c++
int main(int argc, char** argv) {
  // ...
  std::string reply = greeter.SayHello(user);
  std::cout << "Greeter received: " << reply << std::endl;

  reply = greeter.SayHelloAgain(user);
  std::cout << "Greeter received: " << reply << std::endl;

  return 0;
}
```

#### Run!

Run the client and server like you did before. Execute the following commands
from the example **build** directory `examples/cpp/helloworld/cmake/build`:

1.  Build the client and server after having made changes:

    ```sh
    $ make -j
    ```

2.  Run the server:

    ```sh
    $ ./greeter_server
    ```

3.  On a different terminal, run the client:

    ```sh
    $ ./greeter_client
    ```

    You'll see the following output:

    ```nocode
    Greeter received: Hello world
    Greeter received: Hello again world
    ```

{{< alert title="Note" color="info" >}}
Interested in an **asynchronous** version of the client and server?
You'll find the `greeter_async_{client,server}.cc` files in the
[example's source directory][src].

[src]: https://github.com/grpc/grpc/tree/master/examples/cpp/helloworld

{{< /alert >}}

### What's next

- Learn how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction/)
  and [Core concepts](/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial](../basics/).
- Explore the [API reference](../api).

[examples/protos/helloworld.proto]: https://github.com/grpc/grpc/blob/{{< param grpc_vers.core >}}/examples/protos/helloworld.proto
[github.com/google/protobuf/releases]: https://github.com/google/protobuf/releases
[Installing CMake]: https://cmake.org/install
[pb]: https://developers.google.com/protocol-buffers
[proto3]: https://developers.google.com/protocol-buffers/docs/proto3
[repo]: https://github.com/grpc/grpc/tree/{{< param grpc_vers.core >}}
[using-grpc]: https://github.com/grpc/grpc/tree/master/src/cpp#to-start-using-grpc-c
