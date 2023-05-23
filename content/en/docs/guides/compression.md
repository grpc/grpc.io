---
title: Compression
description: >-
    How to use compression to reduce the bandwidth used by gRPC
---

### Overview

Compression is used to reduce the amount of bandwidth used between peers. The compression supported by gRPC acts at the individual message level.

Depends on language, it's possible to control compression settings at channel, call and message level. Different language also support different compression algorithms including customized compressor. 

### Compression Method Asymmetry Between Peers

gRPC also allows asymmetric compression communication, whereby a response may be compressed differently, if at all. A gRPC peer may choose to respond using a different compression method to that of the request, including not performing any compression, regardless of channel and RPC settings (for example, if compression would result in small or negative gains).

If a client message is compressed by an algorithm that is not supported by a server, the message will result in an `UNIMPLEMENTED` error status on the server. The server will then include a `grpc-accept-encoding` response header which specifies the algorithms that the server accepts. If the client message is compressed using one of the algorithms from the `grpc-accept-encoding` header and an `UNIMPLEMENTED` error status is returned from the server, the cause of the error won't be related to compression. If a server sent data which is compressed by an algorithm that is not supported by the client, an `INTERNAL` error status will occur on the client side.

Note that a peer may choose to not disclose all the encodings it supports. However, if it receives a message compressed in an undisclosed but supported encoding, it will include said encoding in the response's `grpc-accept-encoding` header.

For every message a server is requested to compress using an algorithm it knows the client doesn't support (as indicated by the last `grpc-accept-encoding` header received from the client), it will send the message uncompressed.

### Specific Disabling of Compression

If the user requests to disable compression, the next message will be sent uncompressed. This is instrumental in preventing BEAST/CRIME attacks. This applies to both the unary and streaming cases.

### How to Configure Compression

Based on language, compression can be configured by:
* `ServerOption`, `DialOption` and `CallOption` in Go.
* `withCompression` and `setCompression` option in Java.
* `compression` keyword argument in Pyhton.
* `SetCompressionAlgorithm` channel arguments and `ServerBuilder` in C++.

Please see examples of each languages below for more details.

#### Propagation to child RPCs

The inheritance of the compression configuration by child RPCs is hanlded differently by different languages. Note that in the absence of changes to the parent channel, its configuration will be used.


### Language guaides and examples


| Language | Example          | Documentation          |
|----------|------------------|------------------------|
| C++      | [C++ Example]    | [C++ Documentation]    |
| Go       | [Go Example]     | [Go Documentation]     |
| Java     | [Java Example]   | N/A                    |
| Python   | [Python Example] | [Python Documentation] |


### Additional Resources

* [gRPC Compression]
* [gRPC (Core) Compression Cookbook]
* [gRFC for Python Compression API]

[C++ Example]: (https://github.com/grpc/grpc/tree/master/examples/cpp/compression)
[C++ Documentation]: (https://github.com/grpc/grpc/tree/master/examples/cpp/compression)
[Go Example]: (https://github.com/grpc/grpc-go/tree/master/examples/features/compression)
[Go Documentation]: (https://github.com/grpc/grpc-go/blob/master/Documentation/compression.md)
[Java Example]: (https://github.com/grpc/grpc-java/tree/master/examples/src/main/java/io/grpc/examples/experimental)
[Python Example]: (https://github.com/grpc/grpc/tree/master/examples/python/compression)
[Python Documentation]: (https://github.com/grpc/grpc/tree/master/examples/python/compression)
[gRPC Compression]: (https://github.com/grpc/grpc/blob/master/doc/compression.md)
[gRPC (Core) Compression Cookbook]: (https://github.com/grpc/grpc/blob/master/doc/compression_cookbook.md#per-call-settings)
[gRFC for Python Compression API]: (https://github.com/grpc/proposal/blob/master/L46-python-compression-api.md)