---
title: Reflection
description: >-
  Explains how reflection can be used to improve the transparency and
  interpretability of RPCs.
---

### Overview

Reflection is [a
protocol](https://github.com/grpc/grpc-proto/blob/master/grpc/reflection/v1/reflection.proto)
that gRPC servers can use to declare the protobuf-defined APIs they export over
a standardized RPC service, including all types referenced by the request and
response messages. Clients can then use this information to encode requests and
decode responses in human-readable manner.

Reflection is used heavily by debugging tools such as
[`grpcurl`](https://github.com/fullstorydev/grpcurl) and
[Postman](https://learning.postman.com/docs/sending-requests/grpc/grpc-client-overview/).
One coming from the REST world might compare the gRPC reflection API to serving
an OpenAPI document on the HTTP server presenting the REST API being described.

### Transparency and Interpretability

A big contributor to gRPC's stellar performance is the use of Protobuf for
serialization -- a _binary_ non-human-readable protocol. While this greatly
speeds up an RPC, it can also make it more difficult to manually interact with a
server. Hypothetically, in order to manually send a gRPC request to a server
over HTTP/2 using `curl`, you would have to:

1. Know which RPC services the server exposed.
2. Know the protobuf definition of the request message and all types it
references.
3. Know the protobuf definition of the response message all the types _it_
references.

Then, you'd have to use that knowledge to hand-craft your request message(s) into
binary and painstakingly decode the response message(s). This would be time
consuming, frustrating, and error prone. Instead, the reflection protocol
enables tools to automate this whole process, making it invisible.

### Enabling Reflection on a gRPC Server

Reflection is _not_ automatically enabled on a gRPC server. The server author
must call a few additional functions to add a reflection service. These API calls
differ slightly from language to language and, in some languages, require adding
a dependency on a separate package, named something like `grpc-reflection`

Follow these links below for details on your specific language:

| Language   | Guide                |
|------------|----------------------|
| Java       | [Java example]       |
| Go         | [Go example]         |
| C++        | [C++ example]        |
| Python     | [Python example]     |
| Javascript | [Javascript example] |

[Java example]: https://github.com/grpc/grpc-java/tree/master/examples/example-reflection 

[Go example]: https://github.com/grpc/grpc-go/tree/master/examples/features/reflection 

[C++ example]: https://github.com/grpc/grpc/tree/master/examples/cpp/reflection

[Python example]: https://github.com/grpc/grpc/blob/master/examples/python/helloworld/greeter_server_with_reflection.py

[Javascript example]: https://github.com/grpc/grpc-node/blob/master/examples/reflection/server.js

### Tips
 
Reflection works so seamlessly with tools such as `grpcurl` that oftentimes,
people aren't even aware that it's happening under the hood. However, if
reflection isn't exposed, things won't work seamlessly at all. Instead, the
client will fail with nasty errors. People often run into this when writing the
routing configuration for a gRPC service. The _reflection_ service must be
routed to the appropriate backend as well as the application's main RPC service.

If your gRPC API is accessible to public users, you may _not_ want to expose the
reflection service, as you may consider this a security issue. Ultimately, you
will need to make a call here that strikes the best balance between security and
ease-of-use for you and your users.
