---
title: Service Config
description: >-
  How the service config can be used by service owners to control client
  behavior.
---

### Overview

The service config specifies how gRPC clients should behave when interacting
with a gRPC service. Service owners can provide a service config with expected
behavior of all service clients.

### Behavior controlled by the Service Config

The settings in the service config affect client side load balancing, call
behavior and health checking.

This section outlines the options in the service config, but the full service
config data structure is documented with a [protobuf definition].

#### Load Balancing

A service can be composed of multiple servers and the load balancing
configuration how calls from client will be distributed among those servers.
By default the `pick_first` load balancing policy is utilized, but another
one can be specified in the service config. E.g. by specifying the
`round_robin` policy will make the clients rotate through the servers when
calling the service instead of repeatedly using the first server they know of.

#### Call Behavior

The way remote calls are made can be configured in many ways:

- [Wait-for-ready] can be enabled, which will instruct the client to wait for
  the backend to become available instead of failing a call.
- A call [timeout] can be provided, indicating the maximum time the client is
  willing to wait for a server to respond.
- One of:
  - Retry policy (max attempts, backoff settings, retryable status codes)
  - [Hedging] policy (max attempts, delay, non-fatal status codes)
- Maximum size of request or response messages

{{% alert title="Note" color="info" %}}
These call behavior settings can be specified either *globally*, at a
*service level* or at individual *method level*.

Retry and hedging policies can be further adjusted by setting a *retry
throttling policy* but it will always apply globally across all services
and methods.
{{% /alert %}}

#### Health Checking

A client can be configured to perform [health checking] by providing the name
of the service that provides the standard gRPC health checking service API.


### Acquiring a Service Config

The service config is provided to a client either via name resolution or
programatically by the client application. 

#### Name Resolution

The gRPC [name resolution mechanism] allows for pluggable name resolver
implementations. It is the responsibility of these implementation to both
return the addresses associated with a name as well as well as an associated
service config. This is the mechanism that service owners can use to distribute
their service config out to a fleet of gRPC clients.

- The DNS name resolver that comes with gRPC clients supports service configs
  [stored as TXT records] on the name server.
- The xDS name resolver used with a control plane server in a microservices
  architecture uses the responses it gets from the control plane to construct
  the service config.

{{% alert title="Note" color="info" %}}
Even though the service config structure is documented with a protobuf
definition the internal representation in the client is JSON. Name resolver
implementations are free to store the service config information in any way they
prefer as long as they provide it in JSON format at name resolution time.
{{% /alert %}}


#### Programatically

The gRPC client API provides a way to specify a service config in JSON format.
This is used to provide default values for settings that the name resolver might
not provide values for. It can also be useful in some testing situations.

### Example Service Config

The below example does the following:

- Enables the `round_robin` load balancing policy.
- Sets a default call timeout of 0.1s that applies to all methods in all
  services.
- Overides that timeout to be 1s for the `bar` method in the `foo` service as
  well as all the methods in the `baz` service.


```json
{
  "loadBalancingConfig": [ { "round_robin": {} } ],
  "methodConfig": [
    {
      "name": [],
      "timeout": "0.2s"
    },
    {
      "name": [
        { "service": "foo", "method": "bar" },
        { "service": "baz" }
      ],
      "timeout": "1s"
    }
  ]
}
```

[protobuf definition]:https://github.com/grpc/grpc-proto/blob/master/grpc/service_config/service_config.proto
[timeout]:https://grpc.io/docs/guides/deadlines/
[health checking]:https://grpc.io/docs/guides/health-checking/
[Hedging]:https://grpc.io/docs/guides/request-hedging/
[Wait-for-ready]:https://grpc.io/docs/guides/wait-for-ready/
[name resolution mechanism]:https://github.com/grpc/grpc/blob/master/doc/naming.md
[stored as TXT records]:https://github.com/grpc/proposal/blob/master/A2-service-configs-in-dns.md

