---
author: Gráinne Sheerin, Google SRE
company: Google
company-link: https://www.google.com
date: "2018-02-26T00:00:00Z"
published: true
title: gRPC and Deadlines
url: blog/deadlines
---

**TL;DR Always set a deadline**. This post explains why we recommend being deliberate about setting deadlines, with useful code snippets to show you how.

<!--more-->

When you use gRPC, the gRPC library takes care of communication, marshalling, unmarshalling, and deadline enforcement. Deadlines allow gRPC clients to specify how long they are willing to wait for an RPC to complete before the RPC is terminated with the error `DEADLINE_EXCEEDED`. By default this deadline is a very large number, dependent on the language implementation. How deadlines are specified is also language-dependent. Some language APIs work in terms of a **deadline**, a fixed point in time by which the RPC should complete. Others use a **timeout**, a duration of time after which the RPC times out.

In general, when you don't set a deadline, resources will be held for all in-flight requests, and all requests can potentially reach the maximum timeout. This puts the service at risk of running out of resources, like memory, which would increase the latency of the service, or could crash the entire process in the worst case.

To avoid this, services should specify the longest default deadline they technically support, and clients should wait until the response is no longer useful to them. For the service this can be as simple as providing a comment in the .proto file. For the client this involves setting useful deadlines.

There is no single answer to "What is a good deadline/timeout value?". Your service might be as simple as the [Greeter](https://github.com/grpc/grpc/blob/master/examples/protos/helloworld.proto) in our quick start guides, in which case 100 ms would be fine. Your service might be as complex as a globally-distributed and strongly consistent database. The deadline for a client query will be different from how long they should wait for you to drop their table.

So what do you need to consider to make an informed choice of deadline? Factors to take into account include the end to end latency of the whole system, which RPCs are serial, and which can be made in parallel. You should to be able to put numbers on it, even if it's a rough calculation. Engineers need to understand the service and then set a deliberate deadline for the RPCs between clients and servers.

In gRPC, both the client and server make their own independent and local determination about whether the remote procedure call (RPC) was successful. This means their conclusions may not match! An RPC that finished successfully on the server side can fail on the client side. For example, the server can send the response, but the reply can arrive at the client after their deadline has expired. The client will already have terminated with the status error `DEADLINE_EXCEEDED`. This should be checked for and managed at the application level.

## Setting a deadline

As a client you should always set a deadline for how long you are willing to wait for a reply from the server. Here's an example using the greeting service from our [Quick Start Guides](/docs/quickstart/):

### C++


```cpp
ClientContext context;
time_point deadline = std::chrono::system_clock::now() + 
    std::chrono::milliseconds(100);
context.set_deadline(deadline);
```


### Go


```go
clientDeadline := time.Now().Add(time.Duration(*deadlineMs) * time.Millisecond)
ctx, cancel := context.WithDeadline(ctx, clientDeadline)
```


### Java


```java
response = blockingStub.withDeadlineAfter(deadlineMs, TimeUnit.MILLISECONDS).sayHello(request);
```


This sets the deadline to 100ms from when the client RPC is set to when the response is picked up by the client. 


## Checking deadlines

On the server side, the server can query to see if a particular RPC is no longer wanted. Before a server starts work on a response it is very important to check if there is still a client waiting for it. This is especially important to do before starting expensive processing.

### C++


```cpp
if (context->IsCancelled()) {
  return Status(StatusCode::CANCELLED, "Deadline exceeded or Client cancelled, abandoning.");
}
```


### Go


```go
if ctx.Err() == context.Canceled {
	return status.New(codes.Canceled, "Client cancelled, abandoning.")
}
```


### Java


```java
if (Context.current().isCancelled()) {
  responseObserver.onError(Status.CANCELLED.withDescription("Cancelled by client").asRuntimeException());
  return;
}
```


Is it useful for a server to continue with the request, when you know your client has reached their deadline? It depends. If the response can be cached in the server, it can be worth processing and caching it; particularly if it's resource heavy, and costs you money for each request. This will make future requests faster as the result will already be available.


## Adjusting deadlines

What if you set a deadline but a new release or server version causes a bad regression? The deadline could be too small, resulting in all your requests timing out with `DEADLINE_EXCEEDED`, or too large and your user tail latency is now massive. You can use a flag to set and adjust the deadline.

### C++


```cpp
#include <gflags/gflags.h>
DEFINE_int32(deadline_ms, 20*1000, "Deadline in milliseconds.");

ClientContext context;
time_point deadline = std::chrono::system_clock::now() + 
    std::chrono::milliseconds(FLAGS_deadline_ms);
context.set_deadline(deadline);
```


### Go


```go
var deadlineMs = flag.Int("deadline_ms", 20*1000, "Default deadline in milliseconds.")

ctx, cancel := context.WithTimeout(ctx, time.Duration(*deadlineMs) * time.Millisecond)
```


### Java


```java
@Option(name="--deadline_ms", usage="Deadline in milliseconds.")
private int deadlineMs = 20*1000;

response = blockingStub.withDeadlineAfter(deadlineMs, TimeUnit.MILLISECONDS).sayHello(request);
```


Now the deadline can be adjusted to wait longer to avoid failing, without the need to cherry-pick a release with a different hard coded deadline. This lets you mitigate the issue for users until the regression can be debugged and resolved.
