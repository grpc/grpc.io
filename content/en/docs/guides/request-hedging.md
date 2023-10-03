---
title: "Request Hedging"
description : >-
  Explains what request hedging is and how you can configure it.
---

### Overview

Hedging is one of two configurable retry policies supported by gRPC. With
hedging, a gRPC client sends multiple copies of the same request to different
backends and uses the first response it receives. Subsequently, the client
cancels any outstanding requests and forwards the response to the application.

![Basic hedging diagram](/img/basic_hedge.svg)

### Use cases

Hedging is a technique to reduce tail latency in large scale distributed
systems. While naive implementations could add significant load to the backend
servers, it is possible to get most of the latency reduction effects while
increasing load only modestly. 

For an in-depth discussion on tail latencies, see the seminal article, [The Tail
At Scale], by Jeff Dean and Luiz André
Barroso.


#### Configuring hedging in gRPC

Hedging is configurable via [gRPC Service Config], at a per-method granularity.
The configuration contains the following knobs:

```
"hedgingPolicy": {
  "maxAttempts": INTEGER,
  "hedgingDelay": JSON proto3 Duration type,
  "nonFatalStatusCodes": JSON array of grpc status codes (int or string)
}
```

- `maxAttempts`: maximum number of in-flight requests while waiting for a
successful response. This is a mandatory field, and must be specified. If the
specified value is greater than `5`, gRPC uses a value of `5`. 
- `hedgingDelay`: amount of time that needs to elapse before the client sends out
the next request while waiting for a successful response. This field is
optional, and if left unspecified, results in `maxAttempts` number of requests
all sent out at the same time.
- `nonFatalStatusCodes`: an optional list of grpc status codes. If any of hedged
requests fails with a status code that is not present in this list, all
outstanding requests are canceled and the response is returned to the
application.

#### Hedging policy

When the application makes an RPC call that contains a `hedgingPolicy`
configuration in the Service Config, the original RPC is sent immediately, as
with a standard non-hedged call. After `hedgingDelay` has elapsed without a
successful response, the second RPC will be issued. If neither RPC has received
a response after `hedgingDelay` has elapsed again, a third RPC is sent, and so
on, up to `maxAttempts`. gRPC call deadlines apply to the entire chain of hedged
requests. Once the deadline has passed, the operation fails regardless of
in-flight RPCS, and regardless of the hedging configuration.

When a successful response is received (in response to any of the hedged
requests), all outstanding hedged requests are canceled and the response is
returned to the client application layer.

If an error response with a non-fatal status code (controlled by the
`nonFatalStatusCodes` field) is received from a hedged request, then the next
hedged request in line is sent immediately, shortcutting its hedging delay. If
any other status code is received, all outstanding RPCs are canceled and the
error is returned to the client application layer.

If all instances of a hedged RPC fail, there are no additional retry attempts.
Essentially, hedging can be seen as retrying the original RPC before a failure
is even received.

If server pushback that specifies not to retry is received in response to a
hedged request, no further hedged requests should be issued for the call.

#### Throttling Hedged RPCs

gRPC provides a way to throttle hedged RPCs to prevent server overload.
Throttling can be configured via the Service Config as well using the
`RetryThrottlingPolicy` message. The throttling configuration contains the
following:

```
"retryThrottling": {
  "maxTokens": 10,
  "tokenRatio": 0.1
}
```

For each server name, the gRPC client maintains a `token_count` which is
initially set to `max_tokens`. Every outgoing RPC (regardless of service or
method invoked) changes `token_count` as follows:
- Every failed RPC will decrement the `token_count` by `1`.
- Every successful RPC will increment the `token_count` by `token_ratio`.
 
With hedging, the first request is always sent out, but subsequent hedged
requests are sent only if `token_count` is greater than the threshold (defined
as `max_tokens / 2`). If `token_count` is less than or equal to the threshold,
hedged requests do not block. Instead  they are canceled, and if there are no
other already-sent hedged RPCs the failure is returned to the client
application.

The only requests that are counted as failures for the throttling policy are the
ones that fail with a status code that qualifies as a non-fatal status code, or
that receive a pushback response indicating not to retry. This avoids conflating
server failure with responses to malformed requests (such as the
`INVALID_ARGUMENT` status code).


#### Server Pushback

Servers may explicitly pushback by setting metadata in their response to the
client. If the pushback says not to retry, no further hedged requests will be
sent. If the pushback says to retry after a given delay, the next hedged request
(if any) will be issued after the given delay has elapsed.

Server pushback is specified using the metadata key, `grpc-retry-pushback-ms`.
The value is an ASCII encoded signed 32-bit integer with no unnecessary leading
zeros that represents how many milliseconds to wait before sending the next
hedged request. If the value for pushback is negative or unparseble, then it
will be seen as the server asking the client not to retry at all.

### Resources

- [The Tail At Scale]
- [gRPC Service Config]
- [gRPC Retry Design]

### Language Support

| Language | Example             |
|----------|---------------------|
| Java     | [Java example]      |
| C++      | Not yet available   |
| Go       | Not yet supported   |

[The Tail At Scale]: https://research.google/pubs/pub40801/
[gRPC Service Config]: https://github.com/grpc/grpc/blob/master/doc/service_config.md 
[gRPC Retry Design]: https://github.com/grpc/proposal/blob/master/A6-client-retries.md
[Java example]: https://github.com/grpc/grpc-java/tree/master/examples/src/main/java/io/grpc/examples/hedging
