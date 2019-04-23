---
bodyclass: docs
layout: docs
headline: Python Generated Code Reference
aliases: [/docs/reference/python/generated-code.html]
---

# Python Generated Code Reference

## Introduction

gRPC Python relies on the protocol buffers compiler (`protoc`) to generate
code.  It uses a plugin to supplement the generated code by plain `protoc`
with gRPC-specific code.  For a `.proto` service description containing
gRPC services, the plain `protoc` generated code is synthesized in
a `_pb2.py` file, and the gRPC-specifc code lands in a `_grpc_pb2.py` file.
The latter python module imports the former.  In this guide, we focus
on the gRPC-specific subset of the generated code.

## Illustrative Example

Let's look at the following `FortuneTeller` proto service:

```proto
service FortuneTeller {
  // Returns the horoscope and zodiac sign for the given month and day.
  rpc TellFortune(HoroscopeRequest) returns (HoroscopeResponse) {
    // errors: invalid month or day, fortune unavailable
  }

  // Replaces the fortune for the given zodiac sign with the provided one.
  rpc SuggestFortune(SuggestionRequest) returns (SuggestionResponse) {
    // errors: invalid zodiac sign
  }
}
```

gRPC `protoc` plugin will synthesize code elements along the lines
of what follows in the corresponding `_pb2_grpc.py` file:


```python
import grpc

import fortune_pb2

class FortuneTellerStub(object):

  def __init__(self, channel):
    """Constructor.

    Args:
      channel: A grpc.Channel.
    """
    self.TellFortune = channel.unary_unary(
        '/example.FortuneTeller/TellFortune',
        request_serializer=fortune_pb2.HoroscopeRequest.SerializeToString,
        response_deserializer=fortune_pb2.HoroscopeResponse.FromString,
        )
    self.SuggestFortune = channel.unary_unary(
        '/example.FortuneTeller/SuggestFortune',
        request_serializer=fortune_pb2.SuggestionRequest.SerializeToString,
        response_deserializer=fortune_pb2.SuggestionResponse.FromString,
        )


class FortuneTellerServicer(object):

  def TellFortune(self, request, context):
    """Returns the horoscope and zodiac sign for the given month and day.
    errors: invalid month or day, fortune unavailable
    """
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')

  def SuggestFortune(self, request, context):
    """Replaces the fortune for the given zodiac sign with the provided
one.
    errors: invalid zodiac sign
    """
    context.set_code(grpc.StatusCode.UNIMPLEMENTED)
    context.set_details('Method not implemented!')
    raise NotImplementedError('Method not implemented!')


def add_FortuneTellerServicer_to_server(servicer, server):
  rpc_method_handlers = {
      'TellFortune': grpc.unary_unary_rpc_method_handler(
          servicer.TellFortune,
          request_deserializer=fortune_pb2.HoroscopeRequest.FromString,
          response_serializer=fortune_pb2.HoroscopeResponse.SerializeToString,
      ),
      'SuggestFortune': grpc.unary_unary_rpc_method_handler(
          servicer.SuggestFortune,
          request_deserializer=fortune_pb2.SuggestionRequest.FromString,
          response_serializer=fortune_pb2.SuggestionResponse.SerializeToString,
      ),
  }
  generic_handler = grpc.method_handlers_generic_handler(
      'example.FortuneTeller', rpc_method_handlers)
  server.add_generic_rpc_handlers((generic_handler,))
```

## Code Elements

The gRPC generated code starts by importing the `grpc` package and the plain
`_pb2` module, synthesized by `protoc`, which defines non-gRPC-specifc code
elements, like the classes corresponding to protocol buffers messages and
descriptors used by reflection.

For each service `Foo` in the `.proto` file, three primary elements are
generated:

- [**Stub**](#stub): `FooStub` used by the client to connect to a gRPC service.
- [**Servicer**](#servicer): `FooServicer` used by the server to implement a
  gRPC service.
- [**Registration Function**](#registration-function):
  `add_FooServicer_to_server` function used to register a servicer with a
  `grpc.Server` object.


### Stub

<a name="stub"></a>The generated `Stub` class is used by the gRPC clients.  It
will have a constructor that takes a `grpc.Channel` object and initializes the
stub.  For each method in the service, the initializer adds a corresponding
attribute to the stub object with the same name.  Depending on the RPC type
(*i.e.* unary or streaming), the value of that attribute will be callable
objects of type
[UnaryUnaryMultiCallable](/grpc/python/grpc.html?#grpc.UnaryUnaryMultiCallable),
[UnaryStreamMultiCallable](/grpc/python/grpc.html?#grpc.UnaryStreamMultiCallable),
[StreamUnaryMultiCallable](/grpc/python/grpc.html?#grpc.StreamUnaryMultiCallable),
or
[StreamStreamMultiCallable](/grpc/python/grpc.html?#grpc.StreamStreamMultiCallable).

### Servicer

<a name="servicer"></a>For each service, a `Servicer` class is generated.  This
class is intended to serve as the superclass of a service implementation.  For
each method in the service, a corresponding function in the `Servicer` class
will be synthesized which is intended to be overriden in the actual service
implementation.  Comments associated with code elements
in the `.proto` file will be transferred over as docstrings in
the generated python code.

### Registration Function

<a name="registration-function"></a>For each service, a function will be
generated that registers a `Servicer` object implementing it on a `grpc.Server`
object, so that the server would be able to appropriately route the queries to
the respective servicer.  This function takes an object that implements the
`Servicer`, typically an instance of a subclass of the generated `Servicer`
code element described above, and a
[`grpc.Server`](/grpc/python/_modules/grpc.html#Server)
object.
