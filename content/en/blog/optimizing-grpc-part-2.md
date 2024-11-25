---
title: So You Want to Optimize gRPC - Part 2
date: 2018-04-16
author:
  name: Carl Mastrangelo
  link: https://carlmastrangelo.com/
  position: Google
---

How fast is gRPC?  Pretty fast if you understand how modern clients and servers are built.  In
[part 1](/blog/optimizing-grpc-part-1/), I showed how to get an easy **60%** improvement.  In this
post I show how to get a **10000%** improvement.

<!--more-->

## Setup

As in [part 1](/blog/optimizing-grpc-part-1/), we will start with an existing, Java based,
key-value service.  The service will offer concurrent access for creating, reading, updating,
and deleting keys and values.  All the code can be seen
[here](https://github.com/carl-mastrangelo/kvstore/tree/03-nonblocking-server) if you want to try
it out.

## Server Concurrency

Let's look at the [KvService](https://github.com/carl-mastrangelo/kvstore/blob/f422b1b6e7c69f8c07f96ed4ddba64757242352c/src/main/java/io/grpc/examples/KvService.java)
class.  This service handles the RPCs sent by the client, making sure that none of them
accidentally corrupt the state of storage.  To ensure this, the service uses the `synchronized`
keyword to ensure only one RPC is active at a time:

```java
private final Map<ByteBuffer, ByteBuffer> store = new HashMap<>();

@Override
public synchronized void create(
    CreateRequest request, StreamObserver<CreateResponse> responseObserver) {
  ByteBuffer key = request.getKey().asReadOnlyByteBuffer();
  ByteBuffer value = request.getValue().asReadOnlyByteBuffer();
  simulateWork(WRITE_DELAY_MILLIS);
  if (store.putIfAbsent(key, value) == null) {
    responseObserver.onNext(CreateResponse.getDefaultInstance());
    responseObserver.onCompleted();
    return;
  }
  responseObserver.onError(Status.ALREADY_EXISTS.asRuntimeException());
}
```

While this code is thread safe, it comes at a high price: only one RPC can ever be active!  We
need some way of allowing multiple operations to happen safely at the same time.  Otherwise,
the program can't take advantage of all the available processors.

### Breaking the Lock

To solve this, we need to know a little more about the _semantics_ of our RPCs.  The more we know
about how the RPCs are supposed to work, the more optimizations we can make.  For a key-value
service, we notice that _operations to different keys don't interfere with each other_.  When
we update key 'foo', it has no bearing on the value stored for key 'bar'.  But, our server is
written such that operations to any key must be synchronized with respect to each other.  If we
could make operations to different keys happen concurrently, our server could handle a lot more
load.

With the idea in place, we need to figure out how to modify the server.  The
`synchronized` keyword causes Java to acquire a lock on `this`, which is the instance of
`KvService`.  The lock is acquired when the `create` method is entered, and released on return.
The reason we need synchronization is to protect the `store` Map.  Since it is implemented as a
[HashMap](https://en.wikipedia.org/wiki/Hash_table), modifications to it change the internal
arrays.  Because the internal state of the `HashMap` will be corrupted if not properly
synchronized, we can't just remove the synchronization on the method.

However, Java offers a solution here: `ConcurrentHashMap`.  This class offers the ability to
safely access the contents of the map concurrently.  For example, in our usage we want to check
if a key is present.   If not present, we want to add it, else we want to return an error.  The
`putIfAbsent` method atomically checks if a value is present, adds it if not, and tells us if
it succeeded.

Concurrent maps provide stronger guarantees about the safety of `putIfAbsent`, so we can swap the
`HashMap` to a `ConcurrentHashMap` and remove `synchronized`:

```java
private final ConcurrentMap<ByteBuffer, ByteBuffer> store = new ConcurrentHashMap<>();

@Override
public void create(
    CreateRequest request, StreamObserver<CreateResponse> responseObserver) {
  ByteBuffer key = request.getKey().asReadOnlyByteBuffer();
  ByteBuffer value = request.getValue().asReadOnlyByteBuffer();
  simulateWork(WRITE_DELAY_MILLIS);
  if (store.putIfAbsent(key, value) == null) {
    responseObserver.onNext(CreateResponse.getDefaultInstance());
    responseObserver.onCompleted();
    return;
  }
  responseObserver.onError(Status.ALREADY_EXISTS.asRuntimeException());
}
```

### If at First You Don't Succeed

Updating `create` was pretty easy.  Doing the same for `retrieve` and `delete` is easy too.
However, the `update` method is a little trickier.  Let's take a look at what it's doing:

```java
@Override
public synchronized void update(
    UpdateRequest request, StreamObserver<UpdateResponse> responseObserver) {
  ByteBuffer key = request.getKey().asReadOnlyByteBuffer();
  ByteBuffer newValue = request.getValue().asReadOnlyByteBuffer();
  simulateWork(WRITE_DELAY_MILLIS);
  ByteBuffer oldValue = store.get(key);
  if (oldValue == null) {
    responseObserver.onError(Status.NOT_FOUND.asRuntimeException());
    return;
  }
  store.replace(key, oldValue, newValue);
  responseObserver.onNext(UpdateResponse.getDefaultInstance());
  responseObserver.onCompleted();
}
```

Updating a key to a new value needs two interactions with the `store`:

1.  Check to see if the key exists at all.
2.  Update the previous value to the new value.

Unfortunately `ConcurrentMap` doesn't have a straightforward method to do this.  Since we may not
be the only ones modifying the map, we need to handle the possibility that our assumptions
have changed.  We read the old value out, but by the time we replace it, it may have been deleted.

To reconcile this, let's retry if `replace` fails.   It returns true if the replace
was successful.  (`ConcurrentMap` asserts that the operations will not corrupt the internal
structure, but doesn't say that they will succeed!)  We will use a do-while loop:

```java
@Override
public void update(
    UpdateRequest request, StreamObserver<UpdateResponse> responseObserver) {
  // ...
  ByteBuffer oldValue;
  do {
    oldValue = store.get(key);
    if (oldValue == null) {
      responseObserver.onError(Status.NOT_FOUND.asRuntimeException());
      return;
    }
  } while (!store.replace(key, oldValue, newValue));
  responseObserver.onNext(UpdateResponse.getDefaultInstance());
  responseObserver.onCompleted();
}
```

The code wants to fail if it ever sees null, but never if there is a non-null previous value.  One
thing to note is that if _another_ RPC modifies the value between the `store.get()` call and the
`store.replace()` call, it will fail.  This is a non-fatal error for us, so we will just try again.
Once it has successfully put the new value in, the service can respond back to the user.

There is one other possibility that could happen: two RPCs could update the same value and
overwrite each other's work.  While this may be okay for some applications, it would not be
suitable for APIs that provide transactionality.  It is out of scope for this post to show how to
fix this, but be aware it can happen.

## Measuring the Performance

In the last post, we modified the client to be asynchronous and use the gRPC ListenableFuture API.
To avoid running out of memory, the client was modified to have at most **100** active RPCs at a
time.  As we now see from the server code, performance was bottlenecked on acquiring locks.
Since we have removed those, we expect to see a 100x improvement.  The same amount of work is done
per RPC, but a lot more are happening at the same time.  Let's see if our hypothesis holds:

Before:

```sh
./gradlew installDist
time ./build/install/kvstore/bin/kvstore
Apr 16, 2018 10:38:42 AM io.grpc.examples.KvRunner runClient
INFO: Did 24.067 RPCs/s

real	1m0.886s
user	0m9.340s
sys	0m1.660s
```

After:

```node
Apr 16, 2018 10:36:48 AM io.grpc.examples.KvRunner runClient
INFO: Did 2,449.8 RPCs/s

real	1m0.968s
user	0m52.184s
sys	0m20.692s
```

Wow!  From 24 RPCs per second to 2,400 RPCs per second.  And we didn't have to change our API or
our client.  This is why understanding your code and API semantics is important.  By exploiting the
properties of the key-value API, namely the independence of operations on different keys, the code
is now much faster.

One noteworthy artifact of this code is the `user` timing in the results.  Previously the user time
was only 9 seconds, meaning that the CPU was active only 9 of the 60 seconds the code was running.
Afterwards, the usage went up by more than 5x to 52 seconds.  The reason is that more CPU cores are
active.  The `KvServer` is simulating work by sleeping for a few milliseconds.  In a real
application, it would be doing useful work and not have such a dramatic change.  Rather than
scaling per the number of RPCs, it would scale per the number of cores.  Thus, if your machine had
12 cores, you would expect to see a 12x improvement.  Still not bad though!

### More Errors

If you run this code yourself, you will see a lot more log spam in the form:

```nocode
Apr 16, 2018 10:38:40 AM io.grpc.examples.KvClient$3 onFailure
INFO: Key not found
io.grpc.StatusRuntimeException: NOT_FOUND
```

The reason is that the new version of the code makes API level race conditions more apparent.
With 100 times as many RPCs happening, the chance of updates and deletes colliding with each other
is more likely.  To solve this we will need to modify the API definition.   Stay tuned for the next
post showing how to fix this.

## Conclusion

There are a lot of opportunities to optimize your gRPC code.  To take advantage of these, you
need to understand what your code is doing.  This post shows how to convert a lock-based service into
a low-contention, lock-free service.  Always make sure to measure before and after your changes.
