---
title: Best Practices
linkTitle: Best Practices for gRPC C++ API and FAQ
weight: 60
---

## General

*   Please **use the callback API**.
*   **Look for header files with comments** in
    [third_party/grpc/include/grpcpp](https://github.com/grpc/grpc/tree/master/include/grpcpp).
*   **Always set a deadline on RPCs.** Here's a
    [blog post](https://grpc.io/blog/deadlines/) with some explanation. It's
    harder to do so for long-lasting streaming RPCs, but applications can
    implement custom logic to add deadlines for messages.
    <!-- TODO(yashykt): Add example. -->

## Streaming RPCs

*   **Read all messages until failure** if you need all sent messages. Read
    until the reaction is called with bool `ok=false` for callback API or the
    tag has `ok=false` for the async API, or Read fails for the sync API. This
    is more reliable than counting messages.
*   **There can only be one read and one write in flight at a time** This is an
    API requirement rather than a best practice, but worth mentioning again.
*   **If your application has a two-way stream of data, use bi-directional
    streaming rather a client-server and server-client model.** This will allow
    for consistent load balancing and is better supported in gRPC.

## Callback API Specific

In this section, "operations" here are defined as `StartRead`, `StartWrite` (and
variants), and `SendInitialMetadata`. `Finish` is also an operation, but often
not relevant to the discussion.

"Reactions" are defined as the overridable callbacks within the reactor, such as
`OnReadDone`, `OnWriteDone`, `OnCancel`, and `OnInitialMetadataDone`. `OnDone`
is also a reaction, but as the final reaction, the directions here may not be
relevant to it.

Best practices:

*   **Reactions should be fast.** Do not do blocking or long-running/heavy
    weight tasks or sleep. It could impact other RPCs within the process.

### Streaming

*   **Use Holds for starting operations outside reactions.** If you are starting
    operations on the client from outside reactions, you may need to use
    [holds](https://github.com/grpc/grpc/blob/24b050b593a435a625e10672fb9b55e8c6501eea/include/grpcpp/support/client_callback.h#L307).
    This prevents OnDone() from running until holds are removed, preventing
    races for final cleanup with outstanding operations if the stream has an
    error. The `bool ok` value in the reactions will reflect if the stream has
    ended, and operations started after this will all have `ok=false`.

*   **Synchronize reactions.** Reactions can run in parallel. For example,
    `OnReadDone` may run at the same time as `OnWriteDone`. Synchronize
    accordingly.

*   **Read until false** Rather than counting number of messages, etc. read
    until `OnReadDone(ok=false)`.

    On the server side, note that this requires the client to call writes done,
    which is recommended. The server side does not have to do anything special -
    `Finish` signals the end of stream.

    A status sent by the application through the `Finish` call may not be
    visible to the client until all incoming messages have been consumed.

## FAQ

### General

1.  How do I debug gRPC issues?

    See
    [troubleshooting](https://github.com/grpc/grpc/blob/master/TROUBLESHOOTING.md).

### Callback Streaming API

1.  Is a client half-close required or expected?

    A client half-close is strongly recommended so that the server can continue
    to read until `OnReadDone(ok=false)`, which is recommended on both the
    server and client side. However, it is not required -- a server could also
    always choose to Finish() before consuming all client data.

1.  How do I cancel operations on the client side?

    [`ClientContext::TryCancel()`](https://github.com/grpc/grpc/blob/24b050b593a435a625e10672fb9b55e8c6501eea/include/grpcpp/client_context.h#L392)

1.  Does the client need to read the data on the wire before `OnDone` is called?

    The best practice is always to read until `ok=false` on the client side.

    The client must read all incoming data before it can see an OK status from
    server `Finish`. However, an error status such as from cancellation or
    deadline or stream abort may arrive anytime.

    There are no guarantees about whether an explicit server `Finish` with an
    error status will be queued behind server writes or delivered immediately.
    Therefore, the client should always consume all incoming messages by reading
    until `ok=false` to guarantee delivery of the status.

    Since messages are not guaranteed to be delivered if the server calls
    `Finish` with an error status, the error status should not be used to
    communicate success and further directions to a client; trailing metadata
    should be used for this purpose instead.

1.  When is `OnDone` called on the client?

    It is called when there is a status available for the client (all incoming
    data is read and the server has called `Finish` OR the status is an error
    that will be delivered immediately), all user reactions have finished
    running, and all holds are removed.

1.  When is `OnDone` called on the server?

    All reactions must finish running (including `OnCancel` when relevant) and
    server must have called `Finish`.

1.  What is "within-reactor flow" vs. "outside-reactor flow" and why does it
    matter?

    Within-reactor flow is when operations are started from inside reactions (or
    the reactor constructor) such as `OnWriteDone` starting another write. These
    make sense since there can only be one read and one write in flight and
    starting them from the reaction can help maintain that.

    Outside-reactor flow is when operations on the stream are started from
    outside reactions. This makes sense since reactions aren't supposed to block
    and the application may not be ready to perform its next read or write. Note
    that outside-reactor flows require the use of holds to synchronize on the
    client side. Server side uses Finish to synchronize outside-reactor calls;
    the application should not start more operations after calling Finish.

1.  What are holds and how and when do I use them?

    They are used to synchronize when OnDone is called and are only needed with
    outside-reactor flow is used. Note that holds are only on the client side.

1.  What if the server calls `Finish` but the client keeps starting new
    operations, such as with `StartWrite`?

    `OnWriteDone(ok=false)` will be called each time the write is started up
    until `OnDone` is called.

1.  How do we know when a reactor can be deleted?

    The reactor can be deleted in `OnDone`. No methods on the reactor base class
    may be invoked from `OnDone`, and the reactor object will not be accessed by
    gRPC after `OnDone` is called. It is the application's responsibility to
    ensure no operations are started when OnDone is running.

1.  Can reactions run at the same time, e.g. can `OnReadInitialMetadataDone` run
    at the same time as `OnReadDone`?

    Yes, most reactions may run in parallel. Only `OnDone` runs by itself as the
    final operation.

1.  Is `OnReadInitialMetadataDone` called every time, even if the metadata is
    empty?

    Yes, this is used to communicate to the client that the metadata is empty.
    As with all reactions, the user application need not override this reaction.

1.  Is `OnSendInitialMetadataDone` called on the server if the initial metadata
    goes out with the first write rather than because of an explicit
    `SendInitialMetadata`?

    No, it has to be explicitly requested. Implicit calls don’t get callbacks.

1.  If a client calls `WriteLast`, do they get both `OnWriteDone` and
    `OnWritesDoneDone` callbacks invoked? What happens if they call
    `Write(options.set_last_message = true)`?

    If there’s a payload, only `OnWriteDone()` will be called.
    `OnWritesDoneDone` will be called only in response to `WritesDone()`.

1.  Can you call `WritesDone()` while you have a write outstanding (i.e.
    `OnWriteDone()` hasn’t been called yet)?

    Yes, the transport orders these.

1.  When does `OnReadInitialMetadataDone` get called with `ok=false` for the
    client?

    This would be called only if there is an error.

1.  Can a user call `SendInitialMetadata`, `StartWrite` without waiting for
    `OnSendInitialMetadataDone` in the middle?

    This is similar to `StartWrite` and `WritesDone`. We do not need to enforce
    ordering if the transport orders it, but the user may get callbacks invoked
    in any order.

1.  When does server `OnCancel` run?

    Note that this is not specific to streaming. It is called for an out-of-band
    cancellation, i.e. when there is an error on the stream (such as connection
    abort), a cancellation requested on the client or server side, or a deadline
    that expires. It can be used as a signal that the client is no longer
    processing any data.

    It may run in parallel with other reactions. Operations called after
    `OnCancel` or started within `OnCancel` will have their reactions called
    with `ok=false`.

    Note that `OnCancel` no longer runs if the server calls `Finish` specifying
    an error status because that is not considered an out-of-band cancellation.

    Depending on ordering, `OnCancel` may or may not run if `Finish` is called.
    However, `OnDone` is always the final callback.

1.  Does server still need to call `Finish` if `OnCancel` is run?

    Yes, although the status passed to `Finish` is ignored.

1.  Will `OnDone` still be called if `OnCancel` is called?

    Yes, `OnDone` is the final callback and will be called once the server has
    also called `Finish` and all other reactions have completed running.

1.  Can the user call additional operations (Start*) after `OnCancel`?

    Yes, but they will all have reactions run with `ok=false`. It is not valid
    to call them after calling server `Finish`.

1.  When does `IsCancelled()` return true on the `context`?

    This is set when there is an error on the stream, a cancellation requested
    on the client or server side, or a deadline that expires. Once b/138186533
    is resolved, if this kind of error is the reason why reactions are called
    with `ok=false`, it will be set *before* these reactions are called.

1.  Is there a per operation (e.g. `StartRead`) deadline, or only per RPC?

    It is only per RPC.

1.  If a user does `stub->MyBidiStreamRPC(); context->TryCancel()`, does the
    user still need to call `StartCall`?

    Yes, it is required once `stub->MyBidiStreamRPC()` is called.

1.  Is it legal for the server to call `Finish` while there is a Read or Write
    outstanding?

    This is fine for reads and `OnReadDone(ok=false)` is called. Calling
    `Finish` with a write outstanding is not valid API usage, since a Finish can
    be considered a final write with no data, which would violate the
    one-write-in-flight rule.

1.  What happens when the server calls `Finish` with a read outstanding?

    `OnReadDone(ok=false)` is called.

1.  Can you start another operation (e.g. read or write) in the client reactor’s
    `OnDone`?

    No, that is not a legal use of the API.

1.  Can you start operations on the server after calling `Finish`?

    This is not a good practice. However, if you start new operations within
    reactions, their corresponding reactions will be called with `ok=false`.
    Starting them with outside-reaction flow is illegal and problematic since
    the operations may race with `OnDone`.
