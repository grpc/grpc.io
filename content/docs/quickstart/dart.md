---
layout: quickstart
title: Dart Quick Start
short: Dart
description: This guide gets you started with gRPC in Dart with a simple working example.
---

<div id="toc"></div>

### Prerequisites

#### Dart SDK

gRPC requires Dart SDK version 2.0 or higher. Dart gRPC supports Flutter and Server platforms.

For installation instructions, see [Install Dart](https://dart.dev/install).

#### Protocol Buffers v3

While not mandatory to use gRPC, gRPC applications usually leverage Protocol
Buffers v3 for service definitions and data serialization, and our example code
uses Protocol Buffers as well as gRPC.

The simplest way to install the protoc compiler is to download pre-compiled
binaries for your operating system (`protoc-<version>-<os>.zip`) from here:
[https://github.com/google/protobuf/releases](https://github.com/google/protobuf/releases)

  * Unzip this file.
  * Update the environment variable `PATH` to include the path to the `protoc`
    binary file.

Next, install the `protoc` plugin for Dart

```sh
$ pub global activate protoc_plugin
```

The compiler plugin, `protoc-gen-dart`, is installed in `$HOME/.pub-cache/bin`.
It must be in your `PATH` for the protocol compiler, protoc, to find it.

```sh
$ export PATH=$PATH:$HOME/.pub-cache/bin
```

### Download the example

You'll need a local copy of the example code to work through this quickstart.
Download the example code from our GitHub repository (the following command
clones the entire repository, but you just need the examples for this quickstart
and other tutorials):

```sh
# Clone the repository at the latest release to get the example code:
$ git clone https://github.com/grpc/grpc-dart
# Navigate to the "Hello World" Dart example:
$ cd grpc-dart/example/helloworld
```

### Run a gRPC application

From the `example/helloworld` directory:

 1. Download package dependencies

    ```sh
    $ pub get
    ```

 2. Run the server

    ```sh
    $ dart bin/server.dart
    ```

 3. In another terminal, run the client

    ```sh
    $ dart bin/client.dart
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update a gRPC service

In this section you'll update the application with an extra server method.
The gRPC service is defined using protocol buffers.
To learn more about how to define a service in a `.proto`
file see [gRPC Basics: Dart](/docs/tutorials/basic/dart/).
For now, all you need to know is that both the
server and the client "stub" have a `SayHello` RPC method that takes a
`HelloRequest` parameter from the client and returns a `HelloReply` from the
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

Edit `protos/helloworld.proto` and add a new `SayHelloAgain` method, with the
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

### Generate gRPC code

Before you can use the new service method, you need to recompile the updated
proto file.

From the `example/helloworld` directory, run:

```sh
$ protoc --dart_out=grpc:lib/src/generated -Iprotos protos/helloworld.proto
```

You'll find the regenerated request and response classes, and client and server
classes in the `lib/src/generated` directory.

### Update and run the application

You have new generated server and client code, but you still need to implement
and call the new method in the human-written parts of our example application.

#### Update the server

In the same directory, open `bin/server.dart`. Add the following
`sayHelloAgain()` method to the `GreeterService` class:

```dart
class GreeterService extends GreeterServiceBase {
  @override
  Future<HelloReply> sayHello(ServiceCall call, HelloRequest request) async {
    return HelloReply()..message = 'Hello, ${request.name}!';
  }

  @override
  Future<HelloReply> sayHelloAgain(ServiceCall call, HelloRequest request) async {
    return HelloReply()..message = 'Hello again, ${request.name}!';
  }
}
```

#### Update the client

Add a call to `sayHelloAgain()` in `bin/client.dart` like this:

```dart
Future<void> main(List<String> args) async {
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
  );
  final stub = GreeterClient(channel);

  final name = args.isNotEmpty ? args[0] : 'world';

  try {
    var response = await stub.sayHello(HelloRequest()..name = name);
    print('Greeter client received: ${response.message}');
    response = await stub.sayHelloAgain(HelloRequest()..name = name);
    print('Greeter client received: ${response.message}');
  } catch (e) {
    print('Caught error: $e');
  }
  await channel.shutdown();
}
```

#### Run!

Run the client and server like you did before. Execute the following commands
from the `example/helloworld` directory:

 1. Run the server

    ```sh
    $ dart bin/server.dart
    ```

 2. In another terminal, run the client. This time, add a name as a command-line
    argument:

    ```sh
    $ dart bin/client.dart Alice
    ```

You should see the following output in the client terminal:

```sh
Greeter client received: Hello, Alice!
Greeter client received: Hello again, Alice!
```

### What's next

- Read a full explanation of how gRPC works in [What is gRPC?](/docs/guides/)
  and [gRPC Concepts](/docs/guides/concepts/).
- Work through a more detailed tutorial in [gRPC Basics: Dart](/docs/tutorials/basic/dart/).
- Explore the [Dart gRPC API reference][].

[Dart gRPC API reference]: https://pub.dev/documentation/grpc

### Reporting issues

If you find a problem with Dart gRPC, please [file an issue][new issue]
in our issue tracker.

[new issue]: https://github.com/grpc/grpc-dart/issues/new
