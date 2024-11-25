---
title: Quick start
description: This guide gets you started with gRPC in Android Java with a simple working example.
weight: 10
---

### Prerequisites

- [JDK][] version 7 or higher
- Android SDK, API level 16 or higher

   1. Install [Android Studio][] or the Android [command-line tools][].

      [Android Studio]: https://developer.android.com/studio/index.html#downloads
      [command-line tools]: https://developer.android.com/studio/index.html#command-tools

   2. Let other tools and scripts know where to find your Android SDK by setting
      the following environment variable:

      ```sh
      export ANDROID_SDK_ROOT="<path-to-your-android-sdk>"
      ```

- An android device set up for [USB debugging][] or an
  [Android Virtual Device][]

{{% alert title="Note" color="info" %}}
  gRPC Java does not support running a server on an Android device. For this
  quick start, the Android client app will connect to a server running on your
  local (non-Android) computer.
{{% /alert %}}

### Get the example code

The example code is part of the [grpc-java][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone -b {{< param grpc_vers.java >}} https://github.com/grpc/grpc-java
    ```

 2. Change to the examples directory:

    ```sh
    cd grpc-java/examples
    ```

### Run the example

 1. Compile the server:

    ```sh
    ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    ./build/install/examples/bin/hello-world-server
    INFO: Server started, listening on 50051
    ```

 3. From another terminal, build the client and install it on your device:

    ```sh
    (cd android/helloworld; ../../gradlew installDebug)
    ```

 4. Launch the client app from your device.

 5. In the client app, enter the server's **Host** and **Port** information. The
    values you enter depend on the device kind (real or virtual) &mdash; for
    details, see [Connecting to the server](#connecting-to-the-server) below.

 6. Type "Alice" in the **Message** box and click **Send**. You'll see the
    following response:

    ```nocode
    Hello Alice
    ```

Congratulations! You've just run a client-server application with gRPC.

{{% alert title="Note" color="info" %}}
  We've omitted timestamps from the client and server trace output shown in this
  page.
{{% /alert %}}

### Update the gRPC service

In this section you'll update the application by adding an extra server method.
The gRPC service is defined using [protocol buffers][pb]. To learn more about
how to define a service in a `.proto` file see [Basics tutorial][]. For now, all
you need to know is that both the server and the client stub have a `SayHello()`
RPC method that takes a `HelloRequest` parameter from the client and returns a
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

Make the following changes:

 1. Open `src/main/proto/helloworld.proto` and add a new `SayHelloAgain()`
    method with the same request and response types as `SayHello()`:

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

 2. Make the same change to
    `android/helloworld/app/src/main/proto/helloworld.proto`.

Remember to save the files!

### Update the app

When you build the example, the build process regenerates `GreeterGrpc.java`,
which contains the generated gRPC client and server classes. This also
regenerates classes for populating, serializing, and retrieving our request and
response types.

However, you still need to implement and call the new method in the
hand-written parts of the example app.

#### Update the server

Follow the instructions given in [Update the
server](/docs/languages/java/quickstart/#update-the-server) of the Java quick start page.

#### Update the client

Follow these steps:

 1. Open `HelloworldActivity.java` from the
    `android/helloworld/app/src/main/java/io/grpc/helloworldexample` folder.

 2. Locate the method containing the call to `sayHello()`. You'll see these
    lines of code:

    ```java
    HelloReply reply = stub.sayHello(request);
    return reply.getMessage();
    ```

 3. Add a call to `sayHelloAgain()` in the `return` statement expression like
    this:

    ```java
    return reply.getMessage() + "\n" + stub.sayHelloAgain(request).getMessage();
    ```

### Run the updated app

Run the client and server like you did before. Execute the following commands
from the `examples` directory:

 1. Compile the server:

    ```sh
    ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    ./build/install/examples/bin/hello-world-server
    INFO: Server started, listening on 50051
    ```

 3. From another terminal, build the client and install it on your device:

    ```sh
    (cd android/helloworld; ../../gradlew installDebug)
    ```

 4. Launch the client app from your device.

 5. In the client app, enter the server's **Host** and **Port** information. The
    values you enter depend on the device kind (real or virtual)  &mdash; for
    details, see [Connecting to the server](#connecting-to-the-server) below.

 6. Type "Alice" in the **Message** box and click **Send**. You'll see the
    following response:

    ```nocode
    Hello Alice
    Hello again Alice
    ```

### Connecting to the server

#### Connecting from a virtual device

Run the Hello World app on your Android Virtual Device and use the following
values:

- **Host**: `10.0.2.2`
- **Port**: 50051

#### Connecting from a physical device

To run the app on a physical device via USB debugging, you must configure USB
port forwarding using the `adb` command as follows:

```sh
adb reverse tcp:8080 tcp:50051
```

This sets up port forwarding from port `8080` on the device to port `50051` on
the connected computer, which is the port that the Hello World server is
listening on.

In the app, use the following values:

- **Host**: `localhost`
- **Port**: 8080

### What's next

- Learn how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction/)
  and [Core concepts](/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial][].
- Explore the [API reference](../api).

[Android Virtual Device]: https://developer.android.com/studio/run/managing-avds.html
[Basics tutorial]: ../basics/
[download]: https://github.com/grpc/grpc-java/archive/{{< param grpc_vers.java >}}.zip
[grpc-java]: https://github.com/grpc/grpc-java
[JDK]: https://jdk.java.net
[pb]: https://developers.google.com/protocol-buffers
[USB debugging]: https://developer.android.com/studio/command-line/adb.html#Enabling
