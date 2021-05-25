---
title: Performance Best Practices
description: A user guide of both general and language-specific best practices to improve performance.
---

### General

*   Always **re-use stubs and channels** when possible.

*   **Use keepalive pings** to keep HTTP/2 connections alive during periods of
    inactivity to allow initial RPCs to be made quickly without a delay (i.e.
    C++ channel arg GRPC_ARG_KEEPALIVE_TIME_MS). 

*   **Use streaming RPCs** when wanting to avoid continuous RPC initiation,
    which includes connection load balancing at the client-side, starting a new
    HTTP/2 request at the transport layer, and invoking a user-defined method
    handler on the server side. Streams are particularly well-suited to handling
    a long-lived logical flow of data from the client-to-server,
    server-to-client, or in both directions. Streams, however, cannot be load
    balanced once they have started and can be hard to debug for stream
    failures. \
    ***Side note:*** *This does not apply to Python (see Python section for
    details).*

*   Each gRPC channel uses 0 or more HTTP/2 connections and each connection
    usually has a limit on the number of concurrent streams. When the number of
    active RPCs on the connection reaches this limit, additional RPCs are queued
    in the client and must wait for active RPCs to finish before they are sent.
    Applications with high load or long-lived streaming RPCs might see
    performance issues because of this queueing. There are two possible
    solutions:

    1.  **Create a separate channel for each area of high load** in the
        application, or

    2.  **Use a pool of gRPC channels** to randomly distribute RPCs over
        multiple connections (channels must have different channel args to
        prevent re-use so define a use-specific channel arg such as channel
        number). \
        ***Side note:*** *The gRPC team has plans to add a feature to fix these
        performance issues, so any solution involving creating multiple channels
        is a temporary workaround that should eventually not be needed.*

### C++

*   **Do not use Sync API for performance sensitive servers.** If performance
    and/or resource consumption are not concerns, use the Sync API as it is the
    simplest to implement for low-QPS services.

*   **Favor callback API over other APIs for all RPCs**, given that the
    application can avoid all blocking operations or blocking operations can be
    moved to a separate thread.

*   If having to use the async completion-queue API, the **best scalability
    trade-off is having numcpu’s threads and one completion queue per thread**.

*   For the async completion-queue API, make sure to **register enough server
    requests for the desired level of concurrency** to avoid the server
    continuously getting stuck in a slow path that results in essentially serial
    request processing. 

*   **Enable write batching in streams** if message k + 1 does not rely on
    responses from message k by passing a WriteOptions argument to Write with
    buffer_hint set - `stream_writer->Write(message,
    WriteOptions().set_buffer_hint());`

*   *(Special topic)* In the case that your application has unary or server-side
    streaming methods where there will be exactly one request message from the
    client, the **synchronous-with-deferred-read interface** could reduce memory
    usage on busy servers. Read more about the interface
    [here](https://g3doc.corp.google.com/net/grpc/g3doc/cpp/codegen.md#synchronous-with-deferred-read-interface).

*   *(Special topic)*
    [gRPC::GenericStub](https://grpc.github.io/grpc/cpp/grpcpp_2generic_2generic__stub_8h.html)
    can be useful in certain cases when there is high contention / CPU time
    spent on proto serialization. This class allows the application to directly
    send **raw gRPC::ByteBuffer as data** rather than serializing from some
    proto. This can also be helpful if the same data is being sent multiple
    times, with one explicit proto-to-ByteBuffer serialization followed by
    multiple ByteBuffer sends. 

### Java

*   **Use non-blocking stubs** to parallelize RPCs.

*   **Provide a custom executor based on the workload** (cached (default), fixed, forkjoin, etc).

### Python

*   Streaming RPCs create extra threads for receiving and possibly sending the
    messages, which makes **streaming RPCs much slower than unary RPCs** in
    Python.

*   **Using [asyncio](https://grpc.github.io/grpc/python/grpc_asyncio.html)** could improve performance.

*   Using the future API in the sync stack results in the creation of an extra
    thread. **Avoid the future API** if possible.

*   *(Experimental)* An experimental **single-threaded unary-stream
    implementation** is available via the
    [SingleThreadedUnaryStream channel option](https://github.com/grpc/grpc/blob/master/src/python/grpcio/grpc/experimental/__init__.py#L38),
    which can save up to 7% latency per message.