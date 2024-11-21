---
title: Quick start
description: This guide gets you started with gRPC in Dart with a simple working example.
weight: 10
spelling: cSpell:ignore Iprotos
---

### Prerequisites

- **[Dart][]** version 2.12 or higher, through the Dart or [Flutter][] SDKs

  For installation instructions, see [Install Dart][] or [Install Flutter][].

- **[Protocol buffer][pb] compiler**, `protoc`, [version 3][proto3]

  For installation instructions, see [Protocol Buffer Compiler
  Installation][pbc-install].

- **Dart plugin** for the protocol compiler:

   1. Install the protocol compiler plugin for Dart (`protoc-gen-dart`) using
      the following command:

      ```sh
      dart pub global activate protoc_plugin
      ```

   2. Update your `PATH` so that the `protoc` compiler can find the plugin:

      ```sh
      export PATH="$PATH:$HOME/.pub-cache/bin"
      ```

{{% alert title="Note" color="info" %}}
  Dart gRPC supports the Flutter and Server platforms.
{{% /alert %}}

### Get the example code

The example code is part of the [grpc-dart][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone https://github.com/grpc/grpc-dart
    ```

 2. Change to the quick start example directory:

    ```sh
    cd grpc-dart/example/helloworld
    ```

### Run the example

From the `example/helloworld` directory:

 1. Download package dependencies:

    ```sh
    dart pub get
    ```

 2. Run the server:

    ```sh
    dart bin/server.dart
    ```

 3. From another terminal, run the client:

    ```sh
    dart bin/client.dart
    Greeter client received: Hello, world!
    ```

Congratulations! You've just run a client-server application with gRPC.


### Update the app

In this section you'll update the app to make use of an extra server method. The
gRPC service is defined using [protocol buffers][pb]. To learn more about how to
define a service in a `.proto` file, see [Basics tutorial][]. For now, all you
need to know is that both the server and the client stub have a `SayHello()` RPC
method that takes a `HelloRequest` parameter from the client and returns a
`HelloReply` from the server, and that the method is defined like this:

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

#### Update the gRPC service

Open `protos/helloworld.proto` and add a new `SayHelloAgain()` method, with the
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

#### Regenerate gRPC code

Before you can use the new service method, you need to recompile the updated
proto file. From the `example/helloworld` directory, run the following command:

```sh
protoc --dart_out=grpc:lib/src/generated -Iprotos protos/helloworld.proto
```

You'll find the regenerated request and response classes, and client and server
classes in the `lib/src/generated` directory.

Now implement and call the new RPC in the server and client code, respectively.

#### Update the server

Open `bin/server.dart` and add the following `sayHelloAgain()` method to the
`GreeterService` class:

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

### Run the updated app

Run the client and server like you did before. Execute the following commands
from the `example/helloworld` directory:

 1. Run the server:

    ```sh
    dart bin/server.dart
    ```

 2. From another terminal, run the client. This time, add a name as a command-line
    argument:

    ```sh
    dart bin/client.dart Alice
    ```

    You'll see the following output:

    ```sh
    Greeter client received: Hello, Alice!
    Greeter client received: Hello again, Alice!
    ```

### Contributing

If you experience problems with Dart gRPC or have a feature request, [create an
issue][issue] over the [grpc-dart][] repo.

### What's next

- Learn how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction/)
  and [Core concepts](/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial][].
- Explore the [API reference](../api).

[Dart]: https://dart.dev
[Basics tutorial]: ../basics/
[download]: https://github.com/grpc/grpc-dart/archive/master.zip
[Flutter]: https://flutter.dev
[github.com/google/protobuf/releases]: https://github.com/google/protobuf/releases
[grpc-dart]: https://github.com/grpc/grpc-dart
[Install Dart]: https://dart.dev/install
[Install Flutter]: https://flutter.dev/docs/get-started/install
[issue]: https://github.com/grpc/grpc-dart/issues/new
[pb]: https://developers.google.com/protocol-buffers
[proto3]: https://protobuf.dev/programming-guides/proto3
[pbc-install]: /docs/protoc-installation/
