---
title: Service Config
description: >-
  How the service config can be used by service owners to control client
  behavior.
---

### Overview

The service config specifies how gRPC clients should behave when interacting
with a gRPC server. Service owners can provide a service config with expected
behavior of all service clients. The settings in a service config always apply
to a specific target string (e.g. "api.myapp.com"), not globally.

### Behavior controlled by the Service Config

The settings in the service config affect client side load balancing, call
behavior and health checking.

This page outlines the options in the service config, but the full service
config data structure is documented with a [protobuf definition].

#### Load Balancing

A service can be composed of multiple servers and the load balancing
configuration specifies how calls from clients should be distributed among
those servers. By default the `pick_first` load balancing policy is utilized,
but another policy can be specified in the service config. E.g. specifying the
`round_robin` policy will make the clients rotate through the servers instead
of repeatedly using the first server.

#### Call Behavior

RPCs can be configured in many ways:

- With [wait-for-ready] enabled, if a client cannot connect to a backend, the
  RPC will be delayed instead of immediately failing.
- A call [timeout] can be provided, indicating the maximum time the client
  should wait before giving up on the RPC.
- One of:
  - [Retry] policy (max attempts, backoff settings, retryable status codes)
  - [Hedging] policy (max attempts, delay, non-fatal status codes)

{{% alert title="Note" color="info" %}}
These call behavior settings can be limited to an individual service or a
method.

Retry and hedging policies can be further adjusted by setting a *retry
throttling policy* but it will apply across all services and methods.
{{% /alert %}}

#### Health Checking

A client can be configured to perform [health checking] by providing a health
checking name. The client will then use the standard gRPC health checking
service.

### Acquiring a Service Config

A service config can be provided to a client either via name resolution or
programatically by the client application. 

#### Name Resolution

The gRPC [name resolution mechanism] allows for pluggable name resolver
implementations. These implementations return the addresses associated with a
name as well as an associated service config. This is the mechanism
that service owners can use to distribute their service config out to a fleet
of gRPC clients.

- The xDS name resolver converts the xDS configuration it receives from the
  control plane to a corresponding service config.
- The standard DNS name resolver in the Go implementation supports service
  configs [stored as TXT records] on the name server.

{{% alert title="Note" color="info" %}}
Even though the service config structure is documented with a protobuf
definition the internal representation in the client is JSON. Name resolver
implementations are free to store the service config information in any way they
prefer as long as they provide it in JSON format at name resolution time.
{{% /alert %}}


#### Programatically

The gRPC client API provides a way to specify a service config in JSON format.
This is used to provide a default service config that will be used in
situations where the name resolver does not provide a service config. It can
also be useful in some testing situations.

### Example Service Config

The below example does the following:

- Enables the `round_robin` load balancing policy.
- Sets a default call timeout of 1s that applies to all methods in all
  services.
- Overides that timeout to be 2s for the `bar` method in the `foo` service as
  well as all the methods in the `baz` service.


```json
{
  "loadBalancingConfig": [ { "round_robin": {} } ],
  "methodConfig": [
    {
      "name": [{}],
      "timeout": "1s"
    },
    {
      "name": [
        { "service": "foo", "method": "bar" },
        { "service": "baz" }
      ],
      "timeout": "2s"
    }
  ]
}
```

[protobuf definition]:https://github.com/grpc/grpc-proto/blob/master/grpc/service_config/service_config.proto
[timeout]:/docs/guides/deadlines/
[Retry]:https://grpc.io/docs/guides/retry/
[health checking]:/docs/guides/health-checking/
[Hedging]:/docs/guides/request-hedging/
[wait-for-ready]:/docs/guides/wait-for-ready/
[name resolution mechanism]:https://github.com/grpc/grpc/blob/master/doc/naming.md
[stored as TXT records]:https://github.com/grpc/proposal/blob/master/A2-service-configs-in-dns.md

