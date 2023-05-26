---
title: Wait-for-Ready
description: >-
  Explains how to configure RPCs to wait for the server to be ready before sending the request.
---

### Overview

This is a feature which can be used on a stub which will cause the RPCs to wait
(until an optional deadline is exceeded) for the server to become available
before sending the request.  This allows for robust batch workflows as transient server problems
(including startup) won't cause failures.

When an RPC is created while the channel is not in a READY state, without
waitForReady it will immediately return a failure; with waitForReady it will
simply block until the connection becomes ready.  The default is **without**
Wait-for-Ready.

For detailed semantics see [this][grpc doc].

### How to use Wait-for-Ready

You can specify for a stub whether or not it should use Wait-for-Ready which
will automatically be passed along, when an RPC is created, to the associated
stream.

{{% alert title="Note" color="info" %}}
 The RPC can still fail for other reasons besides the server not being
ready, so error handling is still necessary.
{{% /alert %}}

The following shows the sequence of events the occur, when a client sends a
message to a server, based upon channel state and whether or not Wait-for-Ready
is set.
```mermaid
sequenceDiagram
participant A as Application
participant RPC
participant CH as Channel
participant S as Server 
A->>RPC: Create RPC using stub
RPC->>CH: Initiate Communication
alt channel state: READY
  CH->>S: Send message
else Channel state: IDLE
  CH-->>CH: Wait for state change
else Channel state: TRANSIENT_FAILURE
  alt with Wait-for-Ready
    CH-->>CH: Wait for channel<br>becoming READY<br>(or a permanent failure)
    CH->>S: Send message
  else without Wait-for-Ready
    CH->>A: Failure
  end
else Channel state is a Permanent Failure
    CH->>A: Failure
end
```
```mermaid
stateDiagram-v2
   state "Initiating Communication" as IC
   state "Channel State" as CS
   IC-->CS: Check Channel State
   state CS {
      state "Permanent Failure" as PF
      state "TRANSIENT_FAILURE" as TF
      IDLE-->READY
      IDLE-->TF
      READY-->[*]
      IDLE-->PF
      TF-->READY
      READY-->TF
      TF-->PF
      PF-->[*]
   }
  state "MSG sent" as MS
  state "RPC Failed" as RF
  CS-->WAIT:From IDLE
  CS-->WAIT:from Transient\nFailure with\nWait-for-Ready
  WAIT-->CS:State Change 
  CS-->MS: From READY
  CS-->RF: From Permanent failure or\nTransient Failure without\nWait-for-Ready
  MS-->[*]
  RF-->[*]

```

### Alternatives

- Loop until RPC stops returning transient failures.
- Implement an `onReady` Handler and handle your own blocking _(for languages that
  support this)_

### Language Support

| Language | Example           |
|----------|-------------------|
| Java     | [Java example]    |
| Go       | [Go example]      |
| Python   | [Python example]  |

[Java example]: https://github.com/grpc/grpc-java/blob/master/examples/src/main/java/io/grpc/examples/waitforready/WaitForReadyClient.java
[Go example]: https://github.com/grpc/grpc-go/tree/master/examples/features/name_resolving
[Python example]: https://github.com/grpc/grpc/tree/master/examples/python/wait_for_ready
[grpc doc]: https://github.com/grpc/grpc/blob/master/doc/wait-for-ready.md
