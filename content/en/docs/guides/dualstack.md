---
title: "Dualstack Backends"
description: >-
     Explains the dualstack backend feature in gRPC.
---

### Overview

In cases where an endpoint (i.e., a gRPC server) has both an IPv4 and
IPv6 address, it is useful for clients to know both of those addresses,
so that they can reach the endpoint on either of them.  Because only
one of the two protocols may actually be routable between a given
client and endpoint, clients need to try both addresses to see which
one will work.  To minimize connection attempt latency, it is also
desirable for clients to attempt to connect to multiple addresses in
parallel, which is done using the "Happy Eyeballs" algorithm described in
[RFC-8305](https://www.rfc-editor.org/rfc/rfc8305).

In gRPC, it is particularly important for the [Load Balancing
Policy](https://grpc.io/docs/guides/custom-load-balancing) to understand
which addresses are associated with the same endpoint as opposed to
being different endpoints, so that the client does not send twice as
much load to a endpoint with two addresses.  To that end, the [Name
Resolver](https://grpc.io/docs/guides/custom-name-resolution) can return
multiple addresses per endpoint (where an endpoint is a single endpoint),
and that information is communicated to the Load Balancing Policy.

Note that the only name resolver implementation that gRPC provides is a
DNS resolver, which does not support dualstack backends.  This is
because DNS inherently returns a flat list of addresses, with no way to
indicate whether or not multiple addresses actually point to the same
endpoint.

There are two ways to use dualstack endpoints in gRPC:

1. Write your own custom name resolver that returns multiple
   addresses per endpoint.  For more information, see [Custom Name
   Resolution](https://grpc.io/docs/guides/custom-name-resolution).
2. Use an xDS control plane that can communicate multiple addresses
   per endpoint to the client.  For more information, consult the
   documentation for your xDS control plane.

For more information on gRPC dualstack backend support, see [gRFC
A61](https://github.com/grpc/proposal/blob/master/A61-IPv4-IPv6-dualstack-backends.md).

### Custom Resolver Dualstack Examples

| Language | Example          | Notes                                  |
|----------|------------------|----------------------------------------|
| C++      |                  | C++ resolver API not yet public.       |
| Go       |                  | Go dualstack support not yet complete. |
| Java     | [Java example]   |                                        |
| Python   |                  | Python resolver API not yet available. |

[Java example]: https://github.com/grpc/grpc-java/tree/master/examples/example-dualstack
