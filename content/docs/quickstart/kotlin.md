---
layout: quickstart
title: Kotlin Quick Start
short: Kotlin
description: This guide gets you started with gRPC in Kotlin with a simple working example.
---

### Prerequisites

- Kotlin version 1.3 or higher

### Download the example

You'll need a local copy of the example code to work through this quick start.
Download the example code from our GitHub repository (the following command
clones the entire repository, but you just need the examples for this quick start
and other tutorials):

```sh
# Clone the repository at the latest release to get the example code:
$ git clone https://github.com/grpc/grpc-kotlin
# Navigate to the examples:
$ cd grpc-kotlin/examples
```

### Run a gRPC application

From the `examples` directory:

 1. Compile the client and server

    ```sh
    $ ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    $ ./build/install/examples/bin/hello-world-server
    ```

 3. From another terminal, run the client:

    ```sh
    $ ./build/install/examples/bin/hello-world-client
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [gRPC Basics: Kotlin](/docs/tutorials/basic/kotlin/). For now all you need to know is that both the
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
Let's update this so that the `Greeter` service has two methods. Edit
`src/main/proto/hello_world.proto` and update it with a new `SayHelloAgain`
method, with the same request and response types:

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

### Update and run the application

When we recompile the example, normal compilation will regenerate
`HelloWorldGrpcKt.kt`, which contains our generated gRPC client and server classes.
This also regenerates classes for populating, serializing, and retrieving our
request and response types.

However, we still need to implement and call the new method in the human-written
parts of our example application.

#### Update the server

In the same directory, open
`src/main/kotlin/io/grpc/examples/hello_world/HelloWorldServer.kt`. Implement the
new method like this:

```kotlin
private class HelloWorldService : GreeterGrpcKt.GreeterCoroutineImplBase() {
  override suspend fun sayHello(request: HelloRequest) = HelloReply
      .newBuilder()
      .setMessage("Hello ${request.name}")
      .build()

    override suspend fun sayHelloAgain(request: HelloRequest) = HelloReply
      .newBuilder()
      .setMessage("Hello again ${request.name}")
      .build()
}
```

#### Update the client

In the same directory, open
`src/main/kotlin/io/grpc/examples/hello_world/HelloWorldClient.kt`. Call the new
method like this:

```kotlin
class HelloWorldClient constructor(
    private val channel: ManagedChannel
) : Closeable {
  private val stub: GreeterCoroutineStub = GreeterCoroutineStub(channel)

  fun greet(name: String) = runBlocking {
    val request = HelloRequest.newBuilder().setName(name).build()
    try {
      val response = stub.sayHello(request)
      println("Greeter client received: ${response.message}")
      val response = stub.sayHelloAgain(request)
      println("Greeter client received: ${response.message}")
    } catch (e: StatusException) {
      println("RPC failed: ${e.status}")
    }
  }

  override fun close() {
    channel.shutdown().awaitTermination(5, TimeUnit.SECONDS)
  }
}
```

#### Run!

Just like we did before, from the `examples` directory:

 1. Compile the client and server:

    ```sh
    $ ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    $ ./build/install/examples/bin/hello-world-server
    ```

 3. From another terminal, run the client:

    ```sh
    $ ./build/install/examples/bin/hello-world-client
    ```

### What's next

- Read a full explanation of how gRPC works in [What is gRPC?](/docs/guides/)
  and [gRPC Concepts](/docs/guides/concepts/).
- Work through a more detailed tutorial in [gRPC Basics: Kotlin](/docs/tutorials/basic/kotlin/).
- Explore the gRPC Kotlin core API in its [reference
  documentation](/grpc-kotlin/javadoc/).
