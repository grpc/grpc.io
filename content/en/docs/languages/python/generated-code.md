---
title: Generated-code reference
short_title: Generated code
weight: 80
spelling: cSpell:ignore docstrings
---

## Introduction

gRPC Python relies on the protocol buffers compiler (`protoc`) to generate
code.  It uses a plugin to supplement the generated code by plain `protoc`
with gRPC-specific code.  For a `.proto` service description containing
gRPC services, the plain `protoc` generated code is synthesized in
a `_pb2.py` file, and the gRPC-specific code lands in a `_pb2_grpc.py` file.
The latter python module imports the former.  The focus of this page is
on the gRPC-specific subset of the generated code.

## Example

Consider the following `FortuneTeller` proto service:

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

When the service is compiled, the gRPC `protoc` plugin generates code similar to
the following `_pb2_grpc.py` file:


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
`_pb2` module, synthesized by `protoc`, which defines non-gRPC-specific code
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

The generated `Stub` class is used by the gRPC clients.  It
has a constructor that takes a `grpc.Channel` object and initializes the
stub. For each method in the service, the initializer adds a corresponding
attribute to the stub object with the same name.  Depending on the RPC type
(unary or streaming), the value of that attribute will be callable
objects of type
[UnaryUnaryMultiCallable](/grpc/python/grpc.html?#grpc.UnaryUnaryMultiCallable),
[UnaryStreamMultiCallable](/grpc/python/grpc.html?#grpc.UnaryStreamMultiCallable),
[StreamUnaryMultiCallable](/grpc/python/grpc.html?#grpc.StreamUnaryMultiCallable),
or
[StreamStreamMultiCallable](/grpc/python/grpc.html?#grpc.StreamStreamMultiCallable).

### Servicer

For each service, a `Servicer` class is generated, which
serves as the superclass of a service implementation.  For
each method in the service, a corresponding function in the `Servicer` class
is generated. Override this function with the service
implementation.  Comments associated with code elements
in the `.proto` file appear as docstrings in
the generated python code.

### Registration Function

For each service, a function is
generated that registers a `Servicer` object implementing it on a `grpc.Server`
object, so that the server can route queries to
the respective servicer.  This function takes an object that implements the
`Servicer`, typically an instance of a subclass of the generated `Servicer`
code element described above, and a
[grpc.Server](/grpc/python/_modules/grpc.html#Server)
object.
