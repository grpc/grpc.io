---
layout: tutorials
group: basic
title: gRPC Basics - Kotlin
short: Kotlin
description: A basic tutorial introduction to gRPC in Kotlin.
---

This tutorial provides a basic Kotlin programmer's introduction to
working with gRPC.

By walking through this example you'll learn how to:

- Define a service in a .proto file.
- Generate server and client code using the protocol buffer compiler.
- Use the Kotlin gRPC API to write a simple client and server for your service.

It assumes that you have read the [Overview](/docs/) and are familiar
with [protocol buffers](https://developers.google.com/protocol-buffers/docs/overview). Note that the
example in this tutorial uses the proto3 version of the protocol buffers
language: you can find out more in the
[proto3 language
guide](https://developers.google.com/protocol-buffers/docs/proto3).

### Why use gRPC?

Our example is a simple route mapping application that lets clients get
information about features on their route, create a summary of their route, and
exchange route information such as traffic updates with the server and other
clients.

With gRPC we can define our service once in a .proto file and implement clients
and servers in any of gRPC's supported languages, which in turn can be run in
environments ranging from servers inside Google to your own tablet - all the
complexity of communication between different languages and environments is
handled for you by gRPC. We also get all the advantages of working with protocol
buffers, including efficient serialization, a simple IDL, and easy interface
updating.

### Example code and setup

The example code for our tutorial is in
[grpc/grpc-kotlin/examples/src/main/kotlin/io/grpc/examples/routeguide](https://github.com/grpc/grpc-kotlin/tree/master/examples/src/main/kotlin/io/grpc/examples/routeguide).
To download the example, clone the latest release in `grpc-kotlin` repository by
running the following command:

```sh
$ git clone https://github.com/grpc/grpc-kotlin.git
```

Then change your current directory to `grpc-kotlin/examples/routeguide`:

```sh
$ cd grpc-kotlin/examples/routeguide
```

### Defining the service

Our first step (as you'll know from the [Overview](/docs/)) is to
define the gRPC *service* and the method *request* and *response* types using
[protocol
buffers](https://developers.google.com/protocol-buffers/docs/overview). You can
see the complete .proto file in
[grpc-kotlin/examples/src/main/proto/route_guide.proto](https://github.com/grpc/grpc-kotlin/blob/master/examples/src/main/proto/route_guide.proto).

To define a service, you specify a named `service` in the .proto file:

```proto
service RouteGuide {
   ...
}
```

Then you define `rpc` methods inside your service definition, specifying their
request and response types. gRPC lets you define four kinds of service method,
all of which are used in the `RouteGuide` service:

- A *simple RPC* where the client sends a request to the server using the stub
  and waits for a response to come back, just like a normal function call.

  ```proto
  // Obtains the feature at a given position.
  rpc GetFeature(Point) returns (Feature) {}
  ```

- A *server-side streaming RPC* where the client sends a request to the server
  and gets a stream to read a sequence of messages back. The client reads from
  the returned stream until there are no more messages. As you can see in our
  example, you specify a server-side streaming method by placing the `stream`
  keyword before the *response* type.

  ```proto
  // Obtains the Features available within the given Rectangle.  Results are
  // streamed rather than returned at once (e.g. in a response message with a
  // repeated field), as the rectangle may cover a large area and contain a
  // huge number of features.
  rpc ListFeatures(Rectangle) returns (stream Feature) {}
  ```

- A *client-side streaming RPC* where the client writes a sequence of messages
  and sends them to the server, again using a provided stream. Once the client
  has finished writing the messages, it waits for the server to read them all
  and return its response. You specify a client-side streaming method by placing
  the `stream` keyword before the *request* type.

  ```proto
  // Accepts a stream of Points on a route being traversed, returning a
  // RouteSummary when traversal is completed.
  rpc RecordRoute(stream Point) returns (RouteSummary) {}
  ```

- A *bidirectional streaming RPC* where both sides send a sequence of messages
  using a read-write stream. The two streams operate independently, so clients
  and servers can read and write in whatever order they like: for example, the
  server could wait to receive all the client messages before writing its
  responses, or it could alternately read a message then write a message, or
  some other combination of reads and writes. The order of messages in each
  stream is preserved. You specify this type of method by placing the `stream`
  keyword before both the request and the response.

  ```proto
  // Accepts a stream of RouteNotes sent while a route is being traversed,
  // while receiving other RouteNotes (e.g. from other users).
  rpc RouteChat(stream RouteNote) returns (stream RouteNote) {}
  ```

Our `.proto` file also contains protocol buffer message type definitions for all
the request and response types used in our service methods - for example, here's
the `Point` message type:

```proto
// Points are represented as latitude-longitude pairs in the E7 representation
// (degrees multiplied by 10**7 and rounded to the nearest integer).
// Latitudes should be in the range +/- 90 degrees and longitude should be in
// the range +/- 180 degrees (inclusive).
message Point {
  int32 latitude = 1;
  int32 longitude = 2;
}
```

### Generating client and server code

Next we need to generate the gRPC client and server interfaces from our .proto
service definition. We do this using the protocol buffer compiler `protoc` with
a special gRPC Kotlin and Java plugins. You need to use the
[proto3](https://github.com/google/protobuf/releases) compiler (which supports
both proto2 and proto3 syntax) in order to generate gRPC services.

When using Gradle or Maven, the protoc build plugin can generate the necessary
code as part of the build. See the [grpc-kotlin README][] for details.

[grpc-kotlin README]: https://github.com/grpc/grpc-kotlin/blob/master/README.md

The following classes are generated from our service definition:

- `Feature.java`, `Point.java`, `Rectangle.java`, and others which contain all
  the protocol buffer code to populate, serialize, and retrieve our request and
  response message types.
- `RouteGuideGrpcKt.kt`, which contains, among other things:
  - A base class for `RouteGuide` servers to implement,
    `RouteGuideGrpcKt.RouteGuideCoroutineImplBase`, with all the methods defined
    in the `RouteGuide` service.
  - The `RouteGuideCoroutineStub` class that clients use to talk to a
    `RouteGuide` server.

### Creating the server {#server}

First let's look at how we create a `RouteGuide` server. If you're only
interested in creating gRPC clients, you can skip this section and go straight
to [Creating the client](#client) (though you might find it interesting
anyway!).

There are two parts to making our `RouteGuide` service do its job:

- Overriding the service base class generated from our service definition: doing
  the actual "work" of our service.
- Running a gRPC server to listen for requests from clients and return the
  service responses.

You can find our example `RouteGuide` server in
[grpc-kotlin/examples/src/main/kotlin/io/grpc/examples/routeguide/RouteGuideServer.kt](https://github.com/grpc/grpc-kotlin/blob/master/examples/src/main/kotlin/io/grpc/examples/routeguide/RouteGuideServer.kt).
Let's take a closer look at how it works.

#### Implementing RouteGuide

As you can see, our server has a `RouteGuideService` class that extends the
generated `RouteGuideGrpcKt.RouteGuideCoroutineImplBase` abstract class:

```kotlin
class RouteGuideService(
  val features: Collection<Feature>,
  /* ... */
) : RouteGuideGrpcKt.RouteGuideCoroutineImplBase() {
  /* ... */
}
```

#### Simple RPC

`RouteGuideService` implements all our service methods. Let's look at the
simplest method first, `GetFeature()`, which just gets a `Point` from the client
and returns the corresponding feature information from its database in a
`Feature`.

```kotlin
override suspend fun getFeature(request: Point): Feature =
    features.find { it.location == request } ?:
    // No feature was found, return an unnamed feature.
    Feature.newBuilder().apply { location = request }.build()
```

The method accepts a client's `Point` message request as a parameter, and it
returns a `Feature` message as a response. In the method we populate the
`Feature` with the appropriate information, and then `return` it to the gRPC
framework, which sends it back to the client.

##### Server-side streaming RPC

Next let's look at one of our streaming RPCs. `ListFeatures` is a server-side
streaming RPC, so we need to send back multiple `Feature`s to our client.

```kotlin
override fun listFeatures(request: Rectangle): Flow<Feature> =
  features.asFlow().filter { it.exists() && it.location in request }
```

Like the simple RPC, this method gets a request object (the `Rectangle` in which
our client wants to find `Feature`s).

This time, we get as many `Feature` objects as we need to return to the client
-- in this case, we select them from the service's feature collection based on
whether they're inside our request `Rectangle`.

##### Client-side streaming RPC

Now let's look at something a little more complicated: the client-side streaming
method `RecordRoute()`, where we get a stream of `Point`s from the client and
return a single `RouteSummary` with information about their trip.

```kotlin
override suspend fun recordRoute(requests: Flow<Point>): RouteSummary {
  var pointCount = 0
  var featureCount = 0
  var distance = 0
  var previous: Point? = null
  val stopwatch = Stopwatch.createStarted(ticker)
  requests.collect { request ->
    pointCount++
    if (getFeature(request).exists()) {
      featureCount++
    }
    val prev = previous
    if (prev != null) {
      distance += prev distanceTo request
    }
    previous = request
  }
  return RouteSummary.newBuilder().apply {
    this.pointCount = pointCount
    this.featureCount = featureCount
    this.distance = distance
    this.elapsedTime = Durations.fromMicros(stopwatch.elapsed(TimeUnit.MICROSECONDS))
  }.build()
}
```

The request parameter is a stream of client request messages represented as a
Kotlin [Flow][]. The server returns a single response just like in the simple
RPC case.

[Flow]: https://kotlinlang.org/docs/reference/coroutines/flow.html#flows

##### Bidirectional streaming RPC

Finally, let's look at our bidirectional streaming RPC `RouteChat()`.

```kotlin
override fun routeChat(requests: Flow<RouteNote>): Flow<RouteNote> =
  flow {
    // could use transform, but it's currently experimental
    requests.collect { note ->
      val notes: MutableList<RouteNote> = routeNotes.computeIfAbsent(note.location) {
        Collections.synchronizedList(mutableListOf<RouteNote>())
      }
      for (prevNote in notes.toTypedArray()) { // thread-safe snapshot
        emit(prevNote)
      }
      notes += note
    }
  }
```

This time we get a stream of `RouteNote` objects that, as in our client-side
streaming example, can be used to access messages.

<!-- However, this time we return
values via our method's returned stream, while the client is still writing
messages to *their* message stream. -->

#### Starting the server

Once we've implemented all our methods, we also need to start up a gRPC server
so that clients can actually use our service. The following snippet shows how we
do this for our `RouteGuide` service:

```kotlin
class RouteGuideServer private constructor(
  val port: Int,
  val server: Server
) {
  constructor(port: Int) : this(port, defaultFeatureSource())

  constructor(port: Int, featureData: ByteSource) :
  this(
    serverBuilder = ServerBuilder.forPort(port),
    port = port,
    features = featureData.parseJsonFeatures()
  )

  constructor(
    serverBuilder: ServerBuilder<*>,
    port: Int,
    features: Collection<Feature>
  ) : this(
    port = port,
    server = serverBuilder.addService(RouteGuideService(features)).build()
  )

  fun start() {
    server.start()
    println("Server started, listening on $port")
    /* ... */
  }

  companion object {
    @JvmStatic
    fun main(args: Array<String>) {
      val port = 8980
      val server = RouteGuideServer(port)
      server.start()
      /* ... */
    }
  }

  /* ... */
}
```
As you can see, we build and start our server using a `ServerBuilder`.

To do this, we:

1. Specify the address and port we want to use to listen for client requests
   using the builder's `forPort()` method.
1. Create an instance of our service implementation class `RouteGuideService`
   and pass it to the builder's `addService()` method.
1. Call `build()` and `start()` on the builder to create and start an RPC server
   for our service.

### Creating the client {#client}

In this section, we'll look at creating a client for our `RouteGuide`
service. You can see our complete example client code in
[grpc-kotlin/examples/src/main/kotlin/io/grpc/examples/routeguide/RouteGuideClient.kt](https://github.com/grpc/grpc-kotlin/blob/master/examples/src/main/kotlin/io/grpc/examples/routeguide/RouteGuideClient.kt).

#### Instantiating a stub

To call service methods, we first need to create a gRPC *channel* to communicate
with the server. We use a `ManagedChannelBuilder` to create the channel:

```kotlin
val channel = ManagedChannelBuilder.forAddress("localhost", 8980).usePlaintext()
```

Once the gRPC *channel* is setup, we need a client _stub_ to perform RPCs. We
get it by instantiating `RouteGuideCoroutineStub`, which is available from the
package that we generated from our .proto file.

```kotlin
val stub = RouteGuideCoroutineStub(channel)
```

#### Calling service methods

Now let's look at how we call our service methods.

##### Simple RPC

Calling the simple RPC `GetFeature()` is as straightforward as calling a local
method.

```kotlin
val request = point(latitude, longitude)
val feature = stub.getFeature(request)
```

The stub method `getFeature()` executes the corresponding RPC, suspending until
the RPC completes. We want the client to await (or block) until the RPC
completes, so we make the stub method call inside a [runBlocking][] coroutine
builder. We wrap the entire body of the client class's `getFeature()` helper
method like this:

```kotlin
fun getFeature(latitude: Int, longitude: Int) = runBlocking {
  val request = point(latitude, longitude)
  val feature = stub.getFeature(request)
  if (feature.exists()) { /* ... */ }
}
```

##### Server-side streaming RPC

Next, let's look at a server-side streaming `ListFeatures()` RPC, which returns
a stream of geographical `Feature`s:

```kotlin
fun listFeatures(lowLat: Int, lowLon: Int, hiLat: Int, hiLon: Int) = runBlocking {
  val request = Rectangle.newBuilder()
    .setLo(point(lowLat, lowLon))
    .setHi(point(hiLat, hiLon))
    .build()
  var i = 1
  stub.listFeatures(request).collect { feature ->
    println("Result #${i++}: $feature")
  }
}
```

The stub `listFeatures()` method returns a stream of features in the form of a
`Flow<Feature>` instance. The flow `collect` method allows the client to
processes the server-provided features as they become available.

##### Client-side streaming RPC

With the client-side streaming `RecordRoute()` RPC, we send a stream of
`Point` messages to the server and get back a single `RouteSummary`.

```kotlin
fun recordRoute(points: Flow<Point>) = runBlocking {
  println("*** RecordRoute")
  val summary = stub.recordRoute(points)
  println("Finished trip with ${summary.pointCount} points.")
  println("Passed ${summary.featureCount} features.")
  println("Travelled ${summary.distance} meters.")
  val duration = summary.elapsedTime.seconds
  println("It took $duration seconds.")
}
```

We generate the route points from the points associated with a randomly selected
list of features. The random selection is taken from a previously loaded feature
collection:

```kotlin
fun generateRoutePoints(features: List<Feature>, numPoints: Int): Flow<Point> = flow {
  for (i in 1..numPoints) {
    val feature = features.random(random)
    println("Visiting point ${feature.location.toStr()}")
    emit(feature.location)
    delay(timeMillis = random.nextLong(500L..1500L))
  }
}
```

Note that flow points are emitted lazily, that is, only once the server requests
them. Once a point has been emitted to the flow, the point generator suspends
until the server requests the next point.

##### Bidirectional streaming RPC

Finally, let's look at our bidirectional streaming RPC `RouteChat()`. As in the
case of `RecordRoute()`, we pass to the method a stream that we'll use to write
the request messages to; like in `ListFeatures()`, we get back a stream that we
can use to read response messages from. However, this time we'll send values via
our method's stream while the server is also writing messages to _its_ message
stream.

```kotlin
fun routeChat() = runBlocking {
  println("*** RouteChat")
  val requests = generateOutgoingNotes()
  stub.routeChat(requests).collect { note ->
    println("Got message \"${note.message}\" at ${note.location.toStr()}")
  }
  println("Finished RouteChat")
}

private fun generateOutgoingNotes(): Flow<RouteNote> = flow {
  val notes = listOf(/* ... */)
  for (note in notes) {
    println("Sending message \"${note.message}\" at ${note.location.toStr()}")
    emit(note);
    delay(500)
  }
}
```

The syntax for reading and writing here is very similar to our client-side and
server-side streaming methods. Although each side will always get the other's
messages in the order they were written, both the client and server can read and
write in any order —- the streams operate completely independently.

### Try it out!

 1. Work from the example directory:

    ```sh
    $ cd examples/route_guide
    ```

 2. Compile the client and server

    ```sh
    $ ./gradlew installDist
    ```

 3. Run the server:

    ```sh
    $ ./build/install/examples/bin/route-guide-server
    ```

 4. From another terminal, run the client:

    ```sh
    $ ./build/install/examples/bin/route-guide-client
    ```

You'll see output like this:

```nocode
*** GetFeature: lat=409146138 lon=-746188906
Found feature called "Berkshire Valley Management Area Trail, Jefferson, NJ, USA" at 40.9146138, -74.6188906
*** GetFeature: lat=0 lon=0
Found no feature at 0.0, 0.0
*** ListFeatures: lowLat=400000000 lowLon=-750000000 hiLat=420000000 liLon=-730000000
Result #1: name: "Patriots Path, Mendham, NJ 07945, USA"
location {
  latitude: 407838351
  longitude: -746143763
}
...
Result #64: name: "3 Hasta Way, Newton, NJ 07860, USA"
location {
  latitude: 410248224
  longitude: -747127767
}

*** RecordRoute
Visiting point 40.0066188, -74.6793294
...
Visiting point 40.4318328, -74.0835638
Finished trip with 10 points.
Passed 3 features.
Travelled 93238790 meters.
It took 9 seconds.
*** RouteChat
Sending message "First message" at 0.0, 0.0
Sending message "Second message" at 0.0, 0.0
Got message "First message" at 0.0, 0.0
Sending message "Third message" at 1.0, 0.0
Sending message "Fourth message" at 1.0, 1.0
Sending message "Last message" at 0.0, 0.0
Got message "First message" at 0.0, 0.0
Got message "Second message" at 0.0, 0.0
Finished RouteChat
```
