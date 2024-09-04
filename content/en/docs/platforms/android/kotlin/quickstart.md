---
title: Quick start
description: This guide gets you started with Kotlin gRPC on Android with a simple working example.
weight: 10
---

### Prerequisites

- [Kotlin][] version 1.3 or higher
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
  gRPC Kotlin does not support running a server on an Android device. For this
  quick start, the Android client app will connect to a server running on your
  local (non-Android) computer.
{{% /alert %}}

### Get the example code

The example code is part of the [grpc-kotlin][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone https://github.com/grpc/grpc-kotlin
    ```

 2. Change to the examples directory:

    ```sh
    cd grpc-kotlin/examples
    ```

### Run the example

 1. Compile the server:

    ```sh
    ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    ./server/build/install/server/bin/hello-world-server
    Server started, listening on 50051
    ```

 3. From another terminal, build the client and install it on your device:

    ```sh
    ./gradlew :android:installDebug
    ```

 4. Launch the client app from your device.

 5. Type "Alice" in the **Name** box and click **Send**. You'll see the
    following response:

    ```nocode
    Hello Alice
    ```

Congratulations! You've just run a client-server application with gRPC.

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

Open `helloworld/hello_world.proto` from the
[protos/src/main/proto/io/grpc/examples][protos-src] folder, and add a
new `SayHelloAgain()` method, with the same request and response types:

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

### Update the app

When you build the example, the build process regenerates `HelloWorldProtoGrpcKt.kt`,
which contains the generated gRPC client and server classes. This also
regenerates classes for populating, serializing, and retrieving our request and
response types.

However, you still need to implement and call the new method in the
hand-written parts of the example app.

#### Update the server

Follow the instructions given in [Update the
server](/docs/languages/kotlin/quickstart/#update-the-server) of the Kotlin
quick start page.

#### Update the client

Follow these steps:

 1. Open `helloworld/MainActivity.kt` from the
    [client/src/main/kotlin/io/grpc/examples][client-src] folder.

 2. Locate the function containing the call to `sayHello()`. You'll see these
    lines of code:

    ```kotlin
    val response = greeter.sayHello(request)
    responseText.text = response.message
    ```

 3. Add a call to `sayHelloAgain()` and change how the response message is
    created. Replace the lines of code above with the following:

    ```kotlin
    val response = greeter.sayHello(request)
    val againResponse = greeter.sayHelloAgain(request)
    val message = "${response.message}\n${againResponse.message}"
    responseText.text = message
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
    ./server/build/install/server/bin/hello-world-server
    Server started, listening on 50051
    ```

 3. From another terminal, build the client and install it on your device:

    ```sh
    ./gradlew :android:installDebug
    ```

 4. Launch the client app from your device.

 5. Type "Alice" in the **Message** box and click **Send**. You'll see the
    following response:

    ```nocode
    Hello Alice
    Hello again Alice
    ```

### What's next

- Learn how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction/)
  and [Core concepts](/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial][] for Kotlin/JVM.
- Explore the [API reference](../api).

[Android Virtual Device]: https://developer.android.com/studio/run/managing-avds.html
[Basics tutorial]: /docs/languages/kotlin/basics/
[client-src]: https://github.com/grpc/grpc-kotlin/blob/master/examples/android/src/main/kotlin/io/grpc/examples
[download]: https://github.com/grpc/grpc-kotlin/archive/master.zip
[grpc-kotlin]: https://github.com/grpc/grpc-kotlin
[JDK]: https://jdk.java.net
[Kotlin]: https://kotlinlang.org
[pb]: https://developers.google.com/protocol-buffers
[protos-src]: https://github.com/grpc/grpc-kotlin/tree/master/examples/protos/src/main/proto/io/grpc/examples
[USB debugging]: https://developer.android.com/studio/command-line/adb.html#Enabling
