---
title: Keepalive
description: How to use HTTP/2 PING-based keepalives in gRPC
---

### Overview

HTTP/2 PING-based keepalives are a way to keep a HTTP/2 connection alive even when there is no data being transferred. This is done by periodically sending a PING frame to the other end of the connection. HTTP/2 keepalives can improve performance and reliability of HTTP/2 connections, but it is important to configure the keepalive interval carefully.

{{% alert title="Note" color="info" %}}
  There is a related but separate concern called [Health Checking](https://github.com/grpc/grpc/blob/master/doc/health-checking.md). Health checking allows server to signal whether a *service* is healthy while keepalive is only about the *connection*.
{{% /alert %}}

#### Background

[TCP keepalive](https://en.wikipedia.org/wiki/Keepalive#TCP_keepalive) is a well-known method of maintaining connections and detecting broken connections. When enabled, either side of the connection can send redundant packets, once ACKed by the other side, the connection will be consiered as good. If no ACK after repeated attempts, the connection is deemed broken. Configuration of its variables is provided by the OS on a per-socket level, but is commonly not exposed to higher-level APIs.

TCP keepalive has three parameters to tune:

1. Time (time since last receipt before sending a keepalive).
2. Interval (interval between keepalives when not receiving reply).
3. Retry (number of times to retry sending keepalives).

gRPC uses HTTP/2 which provides a mandatory [PING](https://httpwg.org/specs/rfc7540.html#PING) frame which can be used to estimate round-trip time, bandwidth-delay product, or test the connection. The interval and retry in TPC keepalive don't quite apply to PING because the transport is reliable, so they're replaced with timeout (equivalent to interval * retry) in gRPC PING-based keepalive implementation.

{{% alert title="Note" color="info" %}}
  It's not required for service owners to support kepalive. **Client authors must coordinate with service owners** for whether a particular client-side setting is acceptable. Service owners decide what they are willing to support, including whether they are willing to receive keepalives at all.
{{% /alert %}}

### How configuring keepalive affects a call

For unary RPC with quick replies, keepalive is less likely to be triggered. Keepalive would primarily be triggered when there is a long-lived RPC, which will fail if keepalive check failed and the connection was closed.

For steaming RPC, if the connection is closed, any in-progress RPCs will fail. If a call is streaming data, the stream will also be closed and any data that has not yet been sent will be lost.

### How to enable and configure keepalive

Based on language, keepalive can be configured by:
* `ServerOption` and client `DialOption` in Go.
* Channel and server builder in Java.
* Channel and server options in C++ and Pyhton.

{{% alert title="Warning" color="warning" %}}
  To avoidling DDoS, it's important to take caution while set the keepalive cofigurations. Thus, it is recommended to disables keepalive for HTTP/2 connections with no outstanding streams and for clients to avoid configuring their keepalive much below one minute.
{{% /alert %}}

### Common situations where keepalives can be useful

gRPC HTTP/2 keepalives can be useful in a variety of situations, including but not limited to:

* When streaming data over a long-lived connection which might be considered as idle by proxy or load balancers.
* When connections are expected to be short-lived.
* When network is less reliable (For exmaple, mobile applications).

In general, keepalives can be used to improve the performance and reliability of gRPC connections. However, it is important to configure the keepalive interval carefully to avoid adding unnecessary overhead or increasing the risk of connection timeouts.

### Keepalive configuration specification

| Options | Availability | Description | Client Default | Server Default |
|---|---|---|---|---|
| KEEPALIVE_TIME | Client and Server | The interval in milliseconds between PING frames. | INT_MAX(Disabled) | 27200000 (2 hours) |
| KEEPALIVE_TIMEOUT | Client and Server | The timeout in milliseconds for a PING frame to be acknowledged. If sender does not receive an acknowledgment within this time, it will close the connection. | 20000 (20 seconds) | 20000 (20 seconds) |
| KEEPALIVE_WITHOUT_CALLS | Client | Is it permissible to send keepalive pings from the client without any outstanding streams. | 0 (false) | N/A |
| PERMIT_KEEPALIVE_WITHOUT_CALLS | Server | Is it permissible to send keepalive pings from the client without any outstanding streams. | N/A | 0 (false) |
| PERMIT_KEEPALIVE_TIME | Server | Minimum allowed time between a server receiving successive ping frames without sending any data/header frame. | N/A | 300000 (5 minutes) |
| MAX_CONNECTION_IDLE | Server | Maximum time that a channel may have no outstanding rpcs, after which the server will close the connection. | N/A | INT_MAX(Infinite) |
| MAX_CONNECTION_AGE | Server | Maximum time that a channel may exist. | N/A | INT_MAX(Infinite) |
| MAX_CONNECTION_AGE_GRACE | Server | Grace period after the channel reaches its max age. | N/A | INT_MAX(Infinite) |


{{% alert title="Note" color="info" %}}
  Some language may provide additional options, please refer to language examples and additional resource for more details.
{{% /alert %}}

### Language guaides and examples

| Language | Example | Documentation |
|---|---|---|
| C++ | N/A | [Link](https://github.com/grpc/grpc/blob/master/doc/keepalive.md) |
| Go | [Link](https://github.com/grpc/grpc-go/tree/master/examples/features/keepalive) | [Link](https://github.com/grpc/grpc-go/blob/master/Documentation/keepalive.md) |
| Java | [Link](https://github.com/grpc/grpc-java/tree/master/examples/src/main/java/io/grpc/examples/keepalive) | N/A |
| Python | [Link](https://github.com/grpc/grpc/tree/master/examples/python/keep_alive) | [Link](https://github.com/grpc/grpc/blob/master/doc/keepalive.md) |
| Node | N/A | N/A |


### Additional Resources

* [gRFC for Client-side Keepalive](https://github.com/grpc/proposal/blob/master/A8-client-side-keepalive.md)
* [gRFC for Server-side Connection Management](https://github.com/grpc/proposal/blob/master/A9-server-side-conn-mgt.md)