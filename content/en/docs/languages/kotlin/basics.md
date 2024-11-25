---
title: Basics tutorial
description: A basic tutorial introduction to gRPC in Kotlin.
spelling: cSpell:ignore grpckt Mendham millis println
weight: 50
---

This tutorial provides a basic Kotlin programmer's introduction to
working with gRPC.

By walking through this example you'll learn how to:

- Define a service in a `.proto` file.
- Generate server and client code using the protocol buffer compiler.
- Use the Kotlin gRPC API to write a simple client and server for your service.

You should already be familiar gRPC and protocol buffers; if not, see
[Introduction to gRPC][] and the proto3 [Language guide][proto3].

### Why use gRPC?

{{< why-grpc >}}

### Setup

This tutorial has the same [prerequisites][] as the [Quick start][]. Install the
necessary SDKs and tools before proceeding.

### Get the example code

The example code is part of the [grpc-kotlin][] repo.

 1. [Download the repo as a zip file][download] and unzip it, or clone
    the repo:

    ```sh
    git clone --depth 1 https://github.com/grpc/grpc-kotlin
    ```

 2. Change to the examples directory:

    ```sh
    cd grpc-kotlin/examples
    ```

### Defining the service

Your first step (as you'll know from the [Introduction to gRPC][]) is to define
the gRPC _service_ and the method _request_ and _response_ types using [protocol
buffers][proto3].

If you'd like to follow along by looking at the complete `.proto` file, see
`routeguide/route_guide.proto` from the
[protos/src/main/proto/io/grpc/examples][protos-src] folder.

To define a service, you specify a named `service` in the `.proto` file like
this:

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

The `.proto` file also contains protocol buffer message type definitions for all
the request and response types used by the service methods -- for example, here's
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

Next, you need to generate the gRPC client and server interfaces from the `.proto`
service definition. You do this using the protocol buffer compiler `protoc` with
special gRPC Kotlin and Java plugins.

When using Gradle or Maven, the `protoc` build plugin will generate the
necessary code as part of the build process. For a Gradle example, see
[stub/build.gradle.kts][].

If you run `./gradlew installDist` from the examples folder, the following files
are generated from the service definition -- you'll find the generated files in
subdirectories below `stub/build/generated/source/proto/main`:

- `Feature.java`, `Point.java`, `Rectangle.java`, and others, which contain all
  the protocol buffer code to populate, serialize, and retrieve our request and
  response message types.

  You'll find these files in the `java/io/grpc/examples/routeguide`
  subdirectory.
- `RouteGuideOuterClassGrpcKt.kt`, which contains, among other things:
  - `RouteGuideGrpcKt.RouteGuideCoroutineImplBase`, an abstract base class for
    `RouteGuide` servers to implement, with all the methods defined in the
    `RouteGuide` service.
  - `RouteGuideGrpcKt.RouteGuideCoroutineStub`, a class that clients use to talk
    to a `RouteGuide` server.

  You'll find this Kotlin file under `grpckt/io/grpc/examples/routeguide`.

### Creating the server {#server}

First consider how to create a `RouteGuide` server. If you're only interested in
creating gRPC clients, skip ahead to [Creating the client](#client) -- though
you might find this section interesting anyway!

There are two main things that you need to do when creating a `RouteGuide`
server:

- Extend the `RouteGuideCoroutineImplBase` service base class to do the actual
  service work.
- Create and run a gRPC server to listen for requests from clients and return
  the service responses.

Open the example `RouteGuide` server code in `routeguide/RouteGuideServer.kt`
under the [server/src/main/kotlin/io/grpc/examples][server-src] folder.

#### Implementing RouteGuide

As you can see, the server has a `RouteGuideService` class that extends the
generated service base class:

```kotlin
class RouteGuideService(
  val features: Collection<Feature>,
  /* ... */
) : RouteGuideGrpcKt.RouteGuideCoroutineImplBase() {
  /* ... */
}
```

##### Simple RPC

`RouteGuideService` implements all the service methods. Consider the simplest
method first, `GetFeature()`, which gets a `Point` from the client and returns a
`Feature` built from the corresponding feature information in the database.

```kotlin
override suspend fun getFeature(request: Point): Feature =
    features.find { it.location == request } ?:
    // No feature was found, return an unnamed feature.
    Feature.newBuilder().apply { location = request }.build()
```

The method accepts a client's `Point` message request as a parameter, and it
returns a `Feature` message as a response. The method populates the `Feature`
with the appropriate information, and then returns it to the gRPC framework,
which sends it back to the client.

##### Server-side streaming RPC

Next, consider one of the streaming RPCs. `ListFeatures()` is a server-side
streaming RPC, so the server gets to send back multiple `Feature` messages to
the client.

```kotlin
override fun listFeatures(request: Rectangle): Flow<Feature> =
  features.asFlow().filter { it.exists() && it.location in request }
```

The request object is a `Rectangle`. The server collects, and returns to the
client, all the `Feature` objects in its collection that are inside the given
`Rectangle`.

##### Client-side streaming RPC

Now consider something a little more complicated: the client-side streaming
method `RecordRoute()`, where the server gets a stream of `Point` objects from
the client, and returns a single `RouteSummary` with information about their
trip through the given points.

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

##### Bidirectional streaming RPC

Finally, consider the bidirectional streaming RPC `RouteChat()`.

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

Similar to the client-side streaming example, for this method, the server gets a
stream of `RouteNote` objects as a `Flow`. However, this time the server returns
`RouteNote` instances via the method's returned stream _while_ the client is still
writing messages to _its_ message stream.

#### Starting the server

Once all the server's methods are implemented, you need code to create a gRPC
server instance, something like this:

```kotlin
class RouteGuideServer(
    val port: Int,
    val features: Collection<Feature> = Database.features(),
    val server: Server =
      ServerBuilder.forPort(port)
        .addService(RouteGuideService(features)).build()
) {

  fun start() {
    server.start()
    println("Server started, listening on $port")
    /* ... */
  }
  /* ... */
}

fun main(args: Array<String>) {
  val port = 8980
  val server = RouteGuideServer(port)
  server.start()
  server.awaitTermination()
 }
```

A server instance is built and started using a `ServerBuilder` as follows:

1. Specify the port, that the server will listen for client requests on, using
   `forPort()`.
1. Create an instance of the service implementation class `RouteGuideService`
   and pass it to the builder's `addService()` method.
1. Call `build()` and `start()` on the builder to create and start an RPC server
   for the route guide service.
1. Call `awaitTermination()` on the server to block the main function until 
   the application receives a signal to terminate.

### Creating the client {#client}

In this section, you'll look at a client for the `RouteGuide` service.

For the complete client code, open `routeguide/RouteGuideClient.kt`
under the [client/src/main/kotlin/io/grpc/examples][client-src] folder.

#### Instantiating a stub

To call service methods, you first need to create a gRPC _channel_ using a
`ManagedChannelBuilder`. You'll use this channel to communicate with the server.

```kotlin
val channel = ManagedChannelBuilder.forAddress("localhost", 8980).usePlaintext().build()
```

Once the gRPC channel is setup, you need a client _stub_ to perform RPCs. Get it
by instantiating `RouteGuideCoroutineStub`, which is available from the package
that was generated from the `.proto` file.

```kotlin
val stub = RouteGuideCoroutineStub(channel)
```

#### Calling service methods

Now consider how you'll call service methods.

##### Simple RPC

Calling the simple RPC `GetFeature()` is as straightforward as calling a local
method:

```kotlin
val request = point(latitude, longitude)
val feature = stub.getFeature(request)
```

The stub method `getFeature()` executes the corresponding RPC, suspending until
the RPC completes:

```kotlin
suspend fun getFeature(latitude: Int, longitude: Int) {
  val request = point(latitude, longitude)
  val feature = stub.getFeature(request)
  if (feature.exists()) { /* ... */ }
}
```

##### Server-side streaming RPC

Next, consider the server-side streaming `ListFeatures()` RPC, which returns a
stream of geographical features:

```kotlin
suspend fun listFeatures(lowLat: Int, lowLon: Int, hiLat: Int, hiLon: Int) {
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
`Flow<Feature>` instance. The flow `collect()` method allows the client to
processes the server-provided features as they become available.

##### Client-side streaming RPC

The client-side streaming `RecordRoute()` RPC sends a stream of `Point` messages
to the server and gets back a single `RouteSummary`.

```kotlin
suspend fun recordRoute(points: Flow<Point>) {
  println("*** RecordRoute")
  val summary = stub.recordRoute(points)
  println("Finished trip with ${summary.pointCount} points.")
  println("Passed ${summary.featureCount} features.")
  println("Travelled ${summary.distance} meters.")
  val duration = summary.elapsedTime.seconds
  println("It took $duration seconds.")
}
```

The method generates the route points from the points associated with a randomly
selected list of features. The random selection is taken from a previously
loaded feature collection:

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

Finally, consider the bidirectional streaming RPC `RouteChat()`. As in the case
of `RecordRoute()`, you pass to the stub method a stream that you use to write
the request messages to; like in `ListFeatures()`, you get back a stream that
you can use to read response messages from. However, this time you send values
via our method's stream while the server is also writing messages to _its_
message stream.

```kotlin
suspend fun routeChat() {
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
    emit(note)
    delay(500)
  }
}
```

The syntax for reading and writing here is very similar to the client-side and
server-side streaming methods. Although each side will always get the other's
messages in the order they were written, both the client and server can read and
write in any order —- the streams operate completely independently.

### Try it out!

Run the following commands from the `grpc-kotlin/examples` directory:

 1. Compile the client and server

    ```sh
    ./gradlew installDist
    ```

 2. Run the server:

    ```sh
    ./server/build/install/server/bin/route-guide-server
    Server started, listening on 8980
    ```

 3. From another terminal, run the client:

    ```sh
    ./client/build/install/client/bin/route-guide-client
    ```

You'll see client output like this:

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

[client-src]: https://github.com/grpc/grpc-kotlin/tree/master/examples/client/src/main/kotlin/io/grpc/examples
[download]: https://github.com/grpc/grpc-kotlin/archive/master.zip
[Flow]: https://kotlinlang.org/docs/reference/coroutines/flow.html#flows
[grpc-kotlin]: https://github.com/grpc/grpc-kotlin
[Introduction to gRPC]: /docs/what-is-grpc/introduction/
[proto3]: https://protobuf.dev/programming-guides/proto3
[Prerequisites]: ../quickstart/#prerequisites
[protos-src]: https://github.com/grpc/grpc-kotlin/tree/master/examples/protos/src/main/proto/io/grpc/examples
[Quick start]: ../quickstart/
[server-src]: https://github.com/grpc/grpc-kotlin/tree/master/examples/server/src/main/kotlin/io/grpc/examples
[stub/build.gradle.kts]: https://github.com/grpc/grpc-kotlin/blob/master/examples/stub/build.gradle.kts
