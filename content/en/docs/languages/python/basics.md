---
title: Basics tutorial
description: A basic tutorial introduction to gRPC in Python.
weight: 50
---

This tutorial provides a basic Python programmer's introduction
to working with gRPC.

By walking through this example you'll learn how to:

- Define a service in a `.proto` file.
- Generate server and client code using the protocol buffer compiler.
- Use the Python gRPC API to write a simple client and server for your service.

It assumes that you have read the [Introduction to gRPC](/docs/what-is-grpc/introduction/) and are familiar
with [protocol
buffers](https://protobuf.dev/overview). You can
find out more in the [proto3 language
guide](https://protobuf.dev/programming-guides/proto3) and [Python
generated code
guide](https://protobuf.dev/reference/python/python-generated).

### Why use gRPC?

{{< why-grpc >}}

### Example code and setup

The example code for this tutorial is in
[grpc/grpc/examples/python/route_guide](https://github.com/grpc/grpc/tree/{{< param grpc_vers.core >}}/examples/python/route_guide).
To download the example, clone the `grpc` repository by running the following
command:

```sh
git clone -b {{< param grpc_vers.core >}} --depth 1 --shallow-submodules https://github.com/grpc/grpc
```

Then change your current directory to `examples/python/route_guide` in the repository:

```sh
cd grpc/examples/python/route_guide
```

You also should have the relevant tools installed to generate the server and
client interface code - if you don't already, follow the setup instructions in
[Quick start](../quickstart/).

### Defining the service

Your first step (as you'll know from the [Introduction to gRPC](/docs/what-is-grpc/introduction/)) is to
define the gRPC *service* and the method *request* and *response* types using
[protocol
buffers](https://protobuf.dev/overview). You can
see the complete `.proto` file in
[`examples/protos/route_guide.proto`](https://github.com/grpc/grpc/blob/{{< param grpc_vers.core >}}/examples/protos/route_guide.proto).

To define a service, you specify a named `service` in your `.proto` file:

```protobuf
service RouteGuide {
   // (Method definitions not shown)
}
```

Then you define `rpc` methods inside your service definition, specifying their
request and response types. gRPC lets you define four kinds of service method,
all of which are used in the `RouteGuide` service:

- A *simple RPC* where the client sends a request to the server using the stub
  and waits for a response to come back, just like a normal function call.

  ```protobuf
  // Obtains the feature at a given position.
  rpc GetFeature(Point) returns (Feature) {}
  ```

- A *response-streaming RPC* where the client sends a request to the server and
  gets a stream to read a sequence of messages back. The client reads from the
  returned stream until there are no more messages. As you can see in the
  example, you specify a response-streaming method by placing the `stream`
  keyword before the *response* type.

  ```protobuf
  // Obtains the Features available within the given Rectangle.  Results are
  // streamed rather than returned at once (e.g. in a response message with a
  // repeated field), as the rectangle may cover a large area and contain a
  // huge number of features.
  rpc ListFeatures(Rectangle) returns (stream Feature) {}
  ```

- A *request-streaming RPC* where the client writes a sequence of messages and
  sends them to the server, again using a provided stream. Once the client has
  finished writing the messages, it waits for the server to read them all and
  return its response. You specify a request-streaming method by placing the
  `stream` keyword before the *request* type.

  ```protobuf
  // Accepts a stream of Points on a route being traversed, returning a
  // RouteSummary when traversal is completed.
  rpc RecordRoute(stream Point) returns (RouteSummary) {}
  ```

- A *bidirectionally-streaming RPC* where both sides send a sequence of messages
  using a read-write stream. The two streams operate independently, so clients
  and servers can read and write in whatever order they like: for example, the
  server could wait to receive all the client messages before writing its
  responses, or it could alternately read a message then write a message, or
  some other combination of reads and writes. The order of messages in each
  stream is preserved. You specify this type of method by placing the `stream`
  keyword before both the request and the response.

  ```protobuf
  // Accepts a stream of RouteNotes sent while a route is being traversed,
  // while receiving other RouteNotes (e.g. from other users).
  rpc RouteChat(stream RouteNote) returns (stream RouteNote) {}
  ```

Your `.proto` file also contains protocol buffer message type definitions for all
the request and response types used in our service methods - for example, here's
the `Point` message type:

```protobuf
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

Next you need to generate the gRPC client and server interfaces from your `.proto`
service definition.

First, install the grpcio-tools package:

```sh
pip install grpcio-tools
```

Use the following command to generate the Python code:

```sh
python -m grpc_tools.protoc -I../../protos --python_out=. --pyi_out=. --grpc_python_out=. ../../protos/route_guide.proto
```

Note that as we've already provided a version of the generated code in the
example directory, running this command regenerates the appropriate file rather
than creates a new one. The generated code files are called
`route_guide_pb2.py` and `route_guide_pb2_grpc.py` and contain:

- classes for the messages defined in `route_guide.proto`
- classes for the service defined in `route_guide.proto`
   - `RouteGuideStub`, which can be used by clients to invoke RouteGuide RPCs
   - `RouteGuideServicer`, which defines the interface for implementations
     of the RouteGuide service
- a function for the service defined in `route_guide.proto`
   - `add_RouteGuideServicer_to_server`, which adds a RouteGuideServicer to
     a `grpc.Server`

{{% alert title="Note" color="info" %}}
The `2` in pb2 indicates that the generated code is following Protocol Buffers Python API version 2. Version 1 is obsolete. It has no relation to the Protocol Buffers Language version, which is the one indicated by `syntax = "proto3"` or `syntax = "proto2"` in a `.proto` file.
{{% /alert %}}

#### Generating gRPC interfaces with custom package path

To generate gRPC client interfaces with a custom package path, you can use the `-I` parameter along with the `grpc_tools.protoc` command. This approach allows you to specify a custom package name for the generated files.

Here's an example command to generate the gRPC client interfaces with a custom package path:

```sh
python -m grpc_tools.protoc -Igrpc/example/custom/path=../../protos \
  --python_out=. --grpc_python_out=. \
  ../../protos/route_guide.proto
```

The generated files will be placed in the `./grpc/example/custom/path/` directory:

- `./grpc/example/custom/path/route_guide_pb2.py`
- `./grpc/example/custom/path/route_guide_pb2_grpc.py`

With this setup, the generated `route_guide_pb2_grpc.py` file will correctly import the protobuf definitions using the custom package structure, as shown below:

```python
import grpc.example.custom.path.route_guide_pb2 as route_guide_pb2
```

By following this approach, you can ensure that the files will call each other correctly with respect to the specified package path. This method allows you to maintain a custom package structure for your gRPC client interfaces.

### Creating the server {#server}

First let's look at how you create a `RouteGuide` server. If you're only
interested in creating gRPC clients, you can skip this section and go straight
to [Creating the client](#client) (though you might find it interesting
anyway!).

Creating and running a `RouteGuide` server breaks down into two work items:
- Implementing the servicer interface generated from our service definition with
  functions that perform the actual "work" of the service.
- Running a gRPC server to listen for requests from clients and transmit
  responses.

You can find the example `RouteGuide` server in
[examples/python/route_guide/route_guide_server.py](https://github.com/grpc/grpc/blob/{{< param grpc_vers.core >}}/examples/python/route_guide/route_guide_server.py).

#### Implementing RouteGuide

`route_guide_server.py` has a `RouteGuideServicer` class that subclasses the
generated class `route_guide_pb2_grpc.RouteGuideServicer`:

```python
# RouteGuideServicer provides an implementation of the methods of the RouteGuide service.
class RouteGuideServicer(route_guide_pb2_grpc.RouteGuideServicer):
```

`RouteGuideServicer` implements all the `RouteGuide` service methods.

##### Simple RPC

Let's look at the simplest type first, `GetFeature`, which just gets a `Point`
from the client and returns the corresponding feature information from its
database in a `Feature`.

```python
def GetFeature(self, request, context):
    feature = get_feature(self.db, request)
    if feature is None:
        return route_guide_pb2.Feature(name="", location=request)
    else:
        return feature
```

The method is passed a `route_guide_pb2.Point` request for the RPC, and a
`grpc.ServicerContext` object that provides RPC-specific information such as
timeout limits. It returns a `route_guide_pb2.Feature` response.

##### Response-streaming RPC

Now let's look at the next method. `ListFeatures` is a response-streaming RPC
that sends multiple `Feature`s to the client.

```python
def ListFeatures(self, request, context):
    left = min(request.lo.longitude, request.hi.longitude)
    right = max(request.lo.longitude, request.hi.longitude)
    top = max(request.lo.latitude, request.hi.latitude)
    bottom = min(request.lo.latitude, request.hi.latitude)
    for feature in self.db:
        if (
            feature.location.longitude >= left
            and feature.location.longitude <= right
            and feature.location.latitude >= bottom
            and feature.location.latitude <= top
        ):
            yield feature
```

Here the request message is a `route_guide_pb2.Rectangle` within which the
client wants to find `Feature`s. Instead of returning a single response the
method yields zero or more responses.

##### Request-streaming RPC

The request-streaming method `RecordRoute` uses an
[iterator](https://docs.python.org/3/library/stdtypes.html#iterator-types) of
request values and returns a single response value.

```python
def RecordRoute(self, request_iterator, context):
    point_count = 0
    feature_count = 0
    distance = 0.0
    prev_point = None

    start_time = time.time()
    for point in request_iterator:
        point_count += 1
        if get_feature(self.db, point):
            feature_count += 1
        if prev_point:
            distance += get_distance(prev_point, point)
        prev_point = point

    elapsed_time = time.time() - start_time
    return route_guide_pb2.RouteSummary(
        point_count=point_count,
        feature_count=feature_count,
        distance=int(distance),
        elapsed_time=int(elapsed_time),
    )
```

##### Bidirectional streaming RPC

Lastly let's look at the bidirectionally-streaming method `RouteChat`.

```python
def RouteChat(self, request_iterator, context):
    prev_notes = []
    for new_note in request_iterator:
        for prev_note in prev_notes:
            if prev_note.location == new_note.location:
                yield prev_note
        prev_notes.append(new_note)
```

This method's semantics are a combination of those of the request-streaming
method and the response-streaming method. It is passed an iterator of request
values and is itself an iterator of response values.

#### Starting the server

Once you have implemented all the `RouteGuide` methods, the next step is to
start up a gRPC server so that clients can actually use your service:

```python
def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    route_guide_pb2_grpc.add_RouteGuideServicer_to_server(RouteGuideServicer(), server)
    server.add_insecure_port("[::]:50051")
    server.start()
    server.wait_for_termination()
```

The server `start()` method is non-blocking. A new thread will be instantiated
to handle requests. The thread calling `server.start()` will often
not have any other work to do in the meantime. In this case, you can call
`server.wait_for_termination()` to cleanly block the calling thread until the
server terminates.

### Creating the client {#client}

You can see the complete example client code in
[examples/python/route_guide/route_guide_client.py](https://github.com/grpc/grpc/blob/{{< param grpc_vers.core >}}/examples/python/route_guide/route_guide_client.py).

#### Creating a stub

To call service methods, we first need to create a *stub*.

We instantiate the `RouteGuideStub` class of the `route_guide_pb2_grpc`
module, generated from our `.proto`.

```python
channel = grpc.insecure_channel('localhost:50051')
stub = route_guide_pb2_grpc.RouteGuideStub(channel)
```

#### Calling service methods

For RPC methods that return a single response ("response-unary" methods), gRPC
Python supports both synchronous (blocking) and asynchronous (non-blocking)
control flow semantics. For response-streaming RPC methods, calls immediately
return an iterator of response values. Calls to that iterator's `next()` method
block until the response to be yielded from the iterator becomes available.

##### Simple RPC

A synchronous call to the simple RPC `GetFeature` is nearly as straightforward
as calling a local method. The RPC call waits for the server to respond, and
will either return a response or raise an exception:

```python
feature = stub.GetFeature(point)
```

An asynchronous call to `GetFeature` is similar, but like calling a local method
asynchronously in a thread pool:

```python
feature_future = stub.GetFeature.future(point)
feature = feature_future.result()
```

##### Response-streaming RPC

Calling the response-streaming `ListFeatures` is similar to working with
sequence types:

```python
for feature in stub.ListFeatures(rectangle):
```

##### Request-streaming RPC

Calling the request-streaming `RecordRoute` is similar to passing an iterator
to a local method. Like the simple RPC above that also returns a single
response, it can be called synchronously or asynchronously:

```python
route_summary = stub.RecordRoute(point_iterator)
```

```python
route_summary_future = stub.RecordRoute.future(point_iterator)
route_summary = route_summary_future.result()
```

##### Bidirectional streaming RPC

Calling the bidirectionally-streaming `RouteChat` has (as is the case on the
service-side) a combination of the request-streaming and response-streaming
semantics:

```python
for received_route_note in stub.RouteChat(sent_route_note_iterator):
```

### Try it out!

Run the server:

```sh
python route_guide_server.py
```

From a different terminal, run the client:

```sh
python route_guide_client.py
```
