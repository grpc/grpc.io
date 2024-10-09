---
title: Keepalive
description: >-
  How to use HTTP/2 PING-based keepalives in gRPC.
---

### Overview

HTTP/2 PING-based keepalives are a way to keep an HTTP/2 connection alive even when there is no data being transferred. This is done by periodically sending a [PING frame] to the other end of the connection. HTTP/2 keepalives can improve performance and reliability of HTTP/2 connections, but it is important to configure the keepalive interval carefully.

{{% alert title="Note" color="info" %}}
  There is a related but separate concern called [Health Checking]. Health checking allows a server to signal whether a *service* is healthy while keepalive is only about the *connection*.
{{% /alert %}}

{{< youtube id="yPNHn6lXndo" class="youtube-video" title="gRPC Keepalive" >}}

### Background

[TCP keepalive] is a well-known method of maintaining connections and detecting broken connections. When TCP keepalive was enabled, either side of the connection can send redundant packets. Once ACKed by the other side, the connection will be considered as good. If no ACK is received after repeated attempts, the connection is deemed broken.

Unlike TCP keepalive, gRPC uses HTTP/2 which provides a mandatory [PING frame] which can be used to estimate round-trip time, bandwidth-delay product, or test the connection. The interval and retry in TCP keepalive don't quite apply to PING because the transport is reliable, so they're replaced with timeout (equivalent to interval * retry) in gRPC PING-based keepalive implementation.

{{% alert title="Note" color="info" %}}
  It's not required for service owners to support keepalive. **Client authors must coordinate with service owners** for whether a particular client-side setting is acceptable. Service owners decide what they are willing to support, including whether they are willing to receive keepalives at all (If the service does not support keepalive, the first few keepalive pings will be ignored, and the server will eventually send a `GOAWAY` message with debug data equal to the ASCII code for `too_many_pings`).
{{% /alert %}}

### How configuring keepalive affects a call

Keepalive is less likely to be triggered for unary RPCs with quick replies. Keepalive is primarily triggered when there is a long-lived RPC, which will fail if the keepalive check fails and the connection is closed.

For streaming RPCs, if the connection is closed, any in-progress RPCs will fail. If a call is streaming data, the stream will also be closed and any data that has not yet been sent will be lost.

{{% alert title="Warning" color="warning" %}}
  To avoid DDoSing, it's important to take caution when setting the keepalive configurations. Thus, it is recommended to avoid enabling keepalive without calls and for clients to avoid configuring their keepalive much below one minute.
{{% /alert %}}

### Common situations where keepalives can be useful

gRPC HTTP/2 keepalives can be useful in a variety of situations, including but not limited to:

* When sending data over a long-lived connection which might be considered as idle by proxy or load balancers.
* When the network is less reliable (For example, mobile applications).
* When using a connection after a long period of inactivity.

### Keepalive configuration specification

| Options | Availability | Description | Client Default | Server Default |
|---|---|---|---|---|
| `KEEPALIVE_TIME` | Client and Server | The interval in milliseconds between PING frames. | INT_MAX (Disabled) | 7200000 (2 hours) |
| `KEEPALIVE_TIMEOUT` | Client and Server | The timeout in milliseconds for a PING frame to be acknowledged. If sender does not receive an acknowledgment within this time, it will close the connection. | 20000 (20 seconds) | 20000 (20 seconds) |
| `KEEPALIVE_WITHOUT_CALLS` | Client | Is it permissible to send keepalive pings from the client without any outstanding streams. | 0 (false) | N/A |
| `PERMIT_KEEPALIVE_WITHOUT_CALLS` | Server | Is it permissible to send keepalive pings from the client without any outstanding streams. | N/A | 0 (false) |
| `PERMIT_KEEPALIVE_TIME` | Server | Minimum allowed time between a server receiving successive ping frames without sending any data/header frame. | N/A | 300000 (5 minutes) |
| `MAX_CONNECTION_IDLE` | Server | Maximum time that a channel may have no outstanding rpcs, after which the server will close the connection. | N/A | INT_MAX (Infinite) |
| `MAX_CONNECTION_AGE` | Server | Maximum time that a channel may exist. | N/A | INT_MAX (Infinite) |
| `MAX_CONNECTION_AGE_GRACE` | Server | Grace period after the channel reaches its max age. | N/A | INT_MAX (Infinite) |


{{% alert title="Note" color="info" %}}
  Some languages may provide additional options, please refer to language examples and additional resource for more details.
{{% /alert %}}

### Language guides and examples

| Language | Example          | Documentation          |
|----------|------------------|------------------------|
| C++      | [C++ Example]    | [C++ Documentation]    |
| Go       | [Go Example]     | [Go Documentation]     |
| Java     | [Java Example]   | [Java Documentation]   |
| Python   | [Python Example] | [Python Documentation] |


### Additional Resources

* [gRFC for Client-side Keepalive]
* [gRFC for Server-side Connection Management]
* [Using gRPC for Long-lived and Streaming RPCs]


[Health Checking]: https://github.com/grpc/grpc/blob/master/doc/health-checking.md
[TCP keepalive]: https://en.wikipedia.org/wiki/Keepalive#TCP_keepalive
[PING frame]: https://httpwg.org/specs/rfc7540.html#PING
[C++ Example]: https://github.com/grpc/grpc/tree/master/examples/cpp/keepalive
[C++ Documentation]: https://github.com/grpc/grpc/blob/master/doc/keepalive.md
[Go Example]: https://github.com/grpc/grpc-go/tree/master/examples/features/keepalive
[Go Documentation]: https://github.com/grpc/grpc-go/blob/master/Documentation/keepalive.md
[Java Example]: https://github.com/grpc/grpc-java/tree/master/examples/src/main/java/io/grpc/examples/keepalive
[Python Example]: https://github.com/grpc/grpc/tree/master/examples/python/keep_alive
[Python Documentation]: https://github.com/grpc/grpc/blob/master/doc/keepalive.md
[gRFC for Client-side Keepalive]: https://github.com/grpc/proposal/blob/master/A8-client-side-keepalive.md
[gRFC for Server-side Connection Management]: https://github.com/grpc/proposal/blob/master/A9-server-side-conn-mgt.md
[Using gRPC for Long-lived and Streaming RPCs]: https://www.youtube.com/watch?v=Naonb2XD_2Q
[Java Documentation]: https://grpc.github.io/grpc-java/javadoc/io/grpc/ManagedChannelBuilder.html#keepAliveTime-long-java.util.concurrent.TimeUnit-
