---
title: Quick Start
description: This guide gets you started with gRPC in Android Java with a simple working example.
weight: 1
---

### Prerequisites

- JDK version 7 or higher
- Android SDK, API level 14 or higher
- An android device set up for [USB debugging][] or an
  [Android Virtual Device][]

[Android Virtual Device]: https://developer.android.com/studio/run/managing-avds.html
[USB debugging]: https://developer.android.com/studio/command-line/adb.html#Enabling

{{< note >}}
gRPC Java does not support running a server on an Android device. For this quick start, the Android client app will connect to a server running on your local (non-Android) computer.
{{< /note >}}

### Download the example

You'll need a local copy of the example code to work through this quick start.
Download the example code from our GitHub repository (the following command
clones the entire repository, but you just need the examples for this quick start
and other tutorials):

```sh
# Clone the repository at the latest release to get the example code:
$ git clone -b {{< param grpc_java_release_tag >}} https://github.com/grpc/grpc-java
# Navigate to the Java examples:
$ cd grpc-java/examples
```

### Run a gRPC application

 1. Compile the server:

    ```sh
    $ ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    $ ./build/install/examples/bin/hello-world-server
    ```

 3. From another terminal, compile and run the client:

    ```sh
    $ cd android/helloworld
    $ ../../gradlew installDebug
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [gRPC Basics: Android Java](/docs/tutorials/basic/android/). For now all you need to know is that both the
server and the client "stub" have a `SayHello` RPC method that takes a
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
Let's update this so that the `Greeter` service has two methods. Edit
`src/main/proto/helloworld.proto` and update it with a new `SayHelloAgain`
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
`GreeterGrpc.java`, which contains our generated gRPC client and server classes.
This also regenerates classes for populating, serializing, and retrieving our
request and response types.

However, we still need to implement and call the new method in the human-written
parts of our example application.

#### Update the server

See the [Java quick start](/docs/quickstart/java/#update-the-server).

#### Update the client

In the same directory, open
`app/src/main/java/io/grpc/helloworldexample/HelloworldActivity.java`. Call the new
method like this:

```java
try {
    HelloRequest message = HelloRequest.newBuilder().setName(mMessage).build();
    HelloReply reply = stub.sayHello(message);
    reply = stub.sayHelloAgain(message);
} catch (Exception e) {
    StringWriter sw = new StringWriter();
    PrintWriter pw = new PrintWriter(sw);
    e.printStackTrace(pw);
    pw.flush();
    return "Failed... : " + System.lineSeparator() + sw;
}
```

#### Run!

Just like we did before, from the `examples` directory:

 1. Compile the server

    ```sh
    $ ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    $ ./build/install/examples/bin/hello-world-server
    ```

 3. From another terminal, compile and install the client to your device

    ```sh
    $ cd android/helloworld
    $ ../../gradlew installDebug
    ```

#### Connecting to the Hello World server via USB

To run the application on a physical device via USB debugging, you must
configure USB port forwarding to allow the device to communicate with the server
running on your computer. This is done via the `adb` command line tool as
follows:

```sh
adb reverse tcp:8080 tcp:50051
```

This sets up port forwarding from port `8080` on the device to port `50051` on
the connected computer, which is the port that the Hello World server is
listening on.

Now you can run the Android Hello World app on your device, using `localhost`
and `8080` as the `Host` and `Port`.

#### Connecting to the Hello World server from an Android Virtual Device

To run the Hello World app on an Android Virtual Device, you don't need to
enable port forwarding. Instead, the emulator can use the IP address
`10.0.2.2` to refer to the host machine. Inside the Android Hello World app,
enter `10.0.2.2` and `50051` as the `Host` and `Port`.

### What's next

- Read a full explanation of how gRPC works in [What is gRPC?](/docs/guides/)
  and [gRPC Concepts](/docs/guides/concepts/).
- Work through a more detailed tutorial in [gRPC Basics: Android Java](/docs/tutorials/basic/android/).
- Explore the gRPC Java core API in its [reference
  documentation](/grpc-java/javadoc/).
