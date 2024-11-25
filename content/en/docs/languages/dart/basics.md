---
title: Basics tutorial
description: A basic tutorial introduction to gRPC in Dart.
weight: 50
spelling: cSpell:ignore pbenum pbgrpc pbjson
---

This tutorial provides a basic Dart programmer's introduction to working with
gRPC.

By walking through this example you'll learn how to:

- Define a service in a `.proto` file.
- Generate server and client code using the protocol buffer compiler.
- Use the Dart gRPC API to write a simple client and server for your service.

It assumes that you have read the [Introduction to gRPC](/docs/what-is-grpc/introduction/) and are familiar
with [protocol buffers](https://protobuf.dev/overview). Note that the
example in this tutorial uses the proto3 version of the protocol buffers
language: you can find out more in the
[proto3 language
guide](https://protobuf.dev/programming-guides/proto3).

### Why use gRPC?

{{< why-grpc >}}

### Example code and setup

The example code for our tutorial is in
[grpc/grpc-dart/example/route_guide](https://github.com/grpc/grpc-dart/tree/master/example/route_guide).
To download the example, clone the `grpc-dart` repository by running the following
command:

```sh
git clone --depth 1 https://github.com/grpc/grpc-dart
```

Then change your current directory to `grpc-dart/example/route_guide`:

```sh
cd grpc-dart/example/route_guide
```

You should have already installed the tools needed to generate client and server
interface code -- if you haven't, see [Quick start][] for setup instructions.

### Defining the service

Our first step (as you'll know from the [Introduction to gRPC](/docs/what-is-grpc/introduction/)) is to
define the gRPC *service* and the method *request* and *response* types using
[protocol buffers](https://protobuf.dev/overview). You can see the
complete `.proto` file in
[`example/route_guide/protos/route_guide.proto`](https://github.com/grpc/grpc-dart/blob/master/example/route_guide/protos/route_guide.proto).

To define a service, you specify a named `service` in your `.proto` file:

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

Next we need to generate the gRPC client and server interfaces from our `.proto`
service definition. We do this using the protocol buffer compiler `protoc` with
a special Dart plugin. This is similar to what we did in the [Quick start][].

From the `route_guide` example directory run:

```sh
protoc -I protos/ protos/route_guide.proto --dart_out=grpc:lib/src/generated
```

Running this command generates the following files in the `lib/src/generated`
directory under the `route_guide` example directory:

- `route_guide.pb.dart`
- `route_guide.pbenum.dart`
- `route_guide.pbgrpc.dart`
- `route_guide.pbjson.dart`

This contains:

- All the protocol buffer code to populate, serialize, and retrieve our request
  and response message types
- An interface type (or *stub*) for clients to call with the methods defined in
  the `RouteGuide` service.
- An interface type for servers to implement, also with the methods defined in
  the `RouteGuide` service.

### Creating the server {#server}

First let's look at how we create a `RouteGuide` server. If you're only
interested in creating gRPC clients, you can skip this section and go straight
to [Creating the client](#client) (though you might find it interesting
anyway!).

There are two parts to making our `RouteGuide` service do its job:

- Implementing the service interface generated from our service definition:
  doing the actual "work" of our service.
- Running a gRPC server to listen for requests from clients and dispatch them to
  the right service implementation.

You can find our example `RouteGuide` server in
[grpc-dart/example/route_guide/lib/src/server.dart](https://github.com/grpc/grpc-dart/tree/master/example/route_guide/lib/src/server.dart).
Let's take a closer look at how it works.

#### Implementing RouteGuide

As you can see, our server has a `RouteGuideService` class that extends the
generated abstract `RouteGuideServiceBase` class:

```dart
class RouteGuideService extends RouteGuideServiceBase {
  Future<Feature> getFeature(grpc.ServiceCall call, Point request) async {
    ...
  }

  Stream<Feature> listFeatures(
      grpc.ServiceCall call, Rectangle request) async* {
    ...
  }

  Future<RouteSummary> recordRoute(
      grpc.ServiceCall call, Stream<Point> request) async {
    ...
  }

  Stream<RouteNote> routeChat(
      grpc.ServiceCall call, Stream<RouteNote> request) async* {
    ...
  }

  ...
}
```

##### Simple RPC

`RouteGuideService` implements all our service methods. Let's look at the
simplest type first, `GetFeature`, which just gets a `Point` from the client and
returns the corresponding feature information from its database in a `Feature`.

```dart
/// GetFeature handler. Returns a feature for the given location.
/// The [context] object provides access to client metadata, cancellation, etc.
@override
Future<Feature> getFeature(grpc.ServiceCall call, Point request) async {
  return featuresDb.firstWhere((f) => f.location == request,
      orElse: () => Feature()..location = request);
}
```

The method is passed a context object for the RPC and the client's `Point`
protocol buffer request. It returns a `Feature` protocol buffer object with the
response information. In the method we populate the `Feature` with the appropriate
information, and then `return` it to the gRPC framework, which sends it back to
the client.

##### Server-side streaming RPC

Now let's look at one of our streaming RPCs. `ListFeatures` is a server-side
streaming RPC, so we need to send back multiple `Feature`s to our client.

```dart
/// ListFeatures handler. Returns a stream of features within the given
/// rectangle.
@override
Stream<Feature> listFeatures(
    grpc.ServiceCall call, Rectangle request) async* {
  final normalizedRectangle = _normalize(request);
  // For each feature, check if it is in the given bounding box
  for (var feature in featuresDb) {
    if (feature.name.isEmpty) continue;
    final location = feature.location;
    if (_contains(normalizedRectangle, location)) {
      yield feature;
    }
  }
}
```

As you can see, instead of getting and returning simple request and response
objects in our method, this time we get a request object (the `Rectangle` in
which our client wants to find `Feature`s) and return a `Stream` of `Feature`
objects.

In the method, we populate as many `Feature` objects as we need to return,
adding them to the returned stream using `yield`. The stream is automatically
closed when the method returns, telling gRPC that we have finished writing
responses.

Should any error happen in this call, the error will be added as an exception
to the stream, and the gRPC layer will translate it into an appropriate RPC
status to be sent on the wire.

##### Client-side streaming RPC

Now let's look at something a little more complicated: the client-side
streaming method `RecordRoute`, where we get a stream of `Point`s from the
client and return a single `RouteSummary` with information about their trip. As
you can see, this time the request parameter is a stream, which the server can
use to both read request messages from the client. The server returns its single
response just like in the simple RPC case.

```dart
/// RecordRoute handler. Gets a stream of points, and responds with statistics
/// about the "trip": number of points, number of known features visited,
/// total distance traveled, and total time spent.
@override
Future<RouteSummary> recordRoute(
    grpc.ServiceCall call, Stream<Point> request) async {
  int pointCount = 0;
  int featureCount = 0;
  double distance = 0.0;
  Point previous;
  final timer = Stopwatch();

  await for (var location in request) {
    if (!timer.isRunning) timer.start();
    pointCount++;
    final feature = featuresDb.firstWhereOrNull((f) => f.location == location);
    if (feature != null) {
      featureCount++;
    }
    // For each point after the first, add the incremental distance from the
    // previous point to the total distance value.
    if (previous != null) distance += _distance(previous, location);
    previous = location;
  }
  timer.stop();
  return RouteSummary()
    ..pointCount = pointCount
    ..featureCount = featureCount
    ..distance = distance.round()
    ..elapsedTime = timer.elapsed.inSeconds;
}
```

In the method body we use `await for` in the request stream to repeatedly read
in our client's requests (in this case `Point` objects) until there are no more
messages. Once the request stream is done, the server can return its
`RouteSummary`.

##### Bidirectional streaming RPC

Finally, let's look at our bidirectional streaming RPC `RouteChat()`.

```dart
/// RouteChat handler. Receives a stream of message/location pairs, and
/// responds with a stream of all previous messages at each of those
/// locations.
@override
Stream<RouteNote> routeChat(
    grpc.ServiceCall call, Stream<RouteNote> request) async* {
  await for (var note in request) {
    final notes = routeNotes.putIfAbsent(note.location, () => <RouteNote>[]);
    for (var note in notes) yield note;
    notes.add(note);
  }
}
```

This time we get a stream of `RouteNote` that, as in our client-side streaming
example, can be used to read messages. However, this time we return values via
our method's returned stream while the client is still writing messages to
*their* message stream.

The syntax for reading and writing here is the same as our client-streaming and
server-streaming methods. Although each side will always get the other's messages
in the order they were written, both the client and server can read and write in
any order — the streams operate completely independently.

#### Starting the server

Once we've implemented all our methods, we also need to start up a gRPC server
so that clients can actually use our service. The following snippet shows how we
do this for our `RouteGuide` service:

```dart
Future<void> main(List<String> args) async {
  final server = grpc.Server.create([RouteGuideService()]);
  await server.serve(port: 8080);
  print('Server listening...');
}
```

To build and start a server, we:

1. Create an instance of the gRPC server using `grpc.Server.create()`,
   giving a list of service implementations.
1. Call `serve()` on the server to start listening for requests, optionally passing
   in the address and port to listen on. The server will continue to serve requests
   asynchronously until `shutdown()` is called on it.

### Creating the client {#client}

In this section, we'll look at creating a Dart client for our `RouteGuide`
service. The complete client code is available from
[grpc-dart/example/route_guide/lib/src/client.dart][].

#### Creating a stub

To call service methods, we first need to create a gRPC *channel* to communicate
with the server. We create this by passing the server address and port number to
`ClientChannel()` as follows:

```dart
final channel = ClientChannel('127.0.0.1',
    port: 8080,
    options: const ChannelOptions(
        credentials: ChannelCredentials.insecure()));
```

You can use `ChannelOptions` to set TLS options (for example, trusted
certificates) for the channel, if necessary.

Once the gRPC *channel* is setup, we need a client *stub* to perform RPCs. We
get it by instantiating `RouteGuideClient`, which is provided by the package
generated from the example `.proto` file.

```dart
stub = RouteGuideClient(channel,
    options: CallOptions(timeout: Duration(seconds: 30)));
```

You can use `CallOptions` to set auth credentials (for example, GCE credentials
or JWT credentials) when a service requires them. The `RouteGuide` service
doesn't require any credentials.

#### Calling service methods

Now let's look at how we call our service methods. Note that in gRPC-Dart, RPCs
are always asynchronous, which means that the RPC returns a `Future` or `Stream`
that must be listened to, to get the response from the server or an error.

##### Simple RPC

Calling the simple RPC `GetFeature` is nearly as straightforward as calling a
local method.

```dart
final point = Point()
  ..latitude = 409146138
  ..longitude = -746188906;
final feature = await stub.getFeature(point));
```

As you can see, we call the method on the stub we got earlier. In our method
parameters we pass a request protocol buffer object (in our case `Point`).
We can also pass an optional `CallOptions` object which lets us change our RPC's
behavior if necessary, such as time-out. If the call doesn't return an error,
the returned `Future` completes with the response information from the server.
If there is an error, the `Future` will complete with the error.

##### Server-side streaming RPC

Here's where we call the server-side streaming method `ListFeatures`, which
returns a stream of geographical `Feature`s. If you've already read [Creating
the server](#server) some of this may look very familiar - streaming RPCs are
implemented in a similar way on both sides.

```dart
final rect = Rectangle()...; // initialize a Rectangle

try {
  await for (var feature in stub.listFeatures(rect)) {
    print(feature);
  }
catch (e) {
  print('ERROR: $e');
}
```

As in the simple RPC, we pass the method a request. However, instead of getting
a `Future` back, we get a `Stream`. The client can use the stream to read the
server's responses.

We use `await for` on the returned stream to repeatedly read in the server's
responses to a response protocol buffer object (in this case a `Feature`) until
there are no more messages.

##### Client-side streaming RPC

The client-side streaming method `RecordRoute` is similar to the server-side
method, except that we pass the method a `Stream` and get a `Future` back.

```dart
final random = Random();

// Generate a number of random points
Stream<Point> generateRoute(int count) async* {
  for (int i = 0; i < count; i++) {
    final point = featuresDb[random.nextInt(featuresDb.length)].location;
    yield point;
  }
}

final pointCount = random.nextInt(100) + 2; // Traverse at least two points

final summary = await stub.recordRoute(generateRoute(pointCount));
print('Route summary: $summary');
```

Since the `generateRoute()` method is `async*`, the points will be generated when
gRPC listens to the request stream and sends the point messages to the server. Once
the stream is done (when `generateRoute()` returns), gRPC knows that we've finished
writing and are expecting to receive a response. The returned `Future` will either
complete with the `RouteSummary` message received from the server, or an error.

##### Bidirectional streaming RPC

Finally, let's look at our bidirectional streaming RPC `RouteChat()`. As in the
case of `RecordRoute`, we pass the method a stream where we will write the request
messages, and like in `ListFeatures`, we get back a stream that we can use to read
the response messages. However, this time we will send values via our method's stream
while the server is also writing messages to *their* message stream.

```dart
Stream<RouteNote> outgoingNotes = ...;

final responses = stub.routeChat(outgoingNotes);
await for (var note in responses) {
  print('Got message ${note.message} at ${note.location.latitude}, ${note
      .location.longitude}');
}
```

The syntax for reading and writing here is very similar to our client-side and
server-side streaming methods. Although each side will always get the other's
messages in the order they were written, both the client and server can read and
write in any order — the streams operate completely independently.

### Try it out!

Work from the example directory:

```sh
cd example/route_guide
```

Get packages:

```sh
dart pub get
```

Run the server:

```sh
dart bin/server.dart
```

From a different terminal, run the client:

```sh
dart bin/client.dart
```

### Reporting issues

If you find a problem with Dart gRPC, please [file an issue][new issue]
in our issue tracker.

[grpc-dart/example/route_guide/lib/src/client.dart]: https://github.com/grpc/grpc-dart/tree/master/example/route_guide/lib/src/client.dart
[new issue]: https://github.com/grpc/grpc-dart/issues/new
[Quick start]: ../quickstart/
