---
title: So You Want to Optimize gRPC - Part 1
date: 2018-03-06
spelling: cSpell:ignore kvstore Mastrangelo MILLIS OOMs
author:
  name: Carl Mastrangelo
  link: https://github.com/carl-mastrangelo
  position: Google
---

A common question with gRPC is how to make it fast.  The gRPC library offers users access to high
performance RPCs, but it isn't always clear how to achieve this.  Because this question is common
enough I thought I would try to show my thought process when tuning programs.

<!--more-->

## Setup

Consider a basic key-value service that is used by multiple other programs.  The service needs to
be safe for concurrent access in case multiple updates happen at the same time.  It needs to be
able to scale up to use the available hardware.   Lastly, it needs to be fast.  gRPC is a perfect
fit for this type of service; let's look at the best way to implement it.

For this blog post, I have written an example
[client and server](https://github.com/carl-mastrangelo/kvstore) using gRPC Java. The program is
split into three main classes, and a protobuf file describing the API:

* [KvClient](https://github.com/carl-mastrangelo/kvstore/blob/01-start/src/main/java/io/grpc/examples/KvClient.java)
  is a simulated user of the key value system.   It randomly creates, retrieves, updates,
  and deletes keys and values.  The size of keys and values it uses is also randomly decided
  using an [exponential distribution](https://en.wikipedia.org/wiki/Exponential_distribution).
* [KvService](https://github.com/carl-mastrangelo/kvstore/blob/01-start/src/main/java/io/grpc/examples/KvService.java)
  is an implementation of the key value service.  It is installed by the gRPC Server to handle
  the requests issued by the client.  To simulate storing the keys and values on disk, it adds
  short sleeps while handling the request.  Reads and writes will experience a 10 and 50
  millisecond delay to make the example act more like a persistent database.
* [KvRunner](https://github.com/carl-mastrangelo/kvstore/blob/01-start/src/main/java/io/grpc/examples/KvRunner.java)
  orchestrates the interaction between the client and the server.  It is the main entry point,
  starting both the client and server in process, and waiting for the the client to execute its
  work.  The runner does work for 60 seconds and then records how many RPCs were completed.
* [kvstore.proto](https://github.com/carl-mastrangelo/kvstore/blob/01-start/src/main/proto/kvstore.proto)
  is the protocol buffer definition of our service.  It describes exactly what clients can expect
  from the service. For the sake of simplicity, we will use Create, Retrieve, Update, and Delete
  as the operations (commonly known as CRUD).  These operations work with keys and values made up
  of arbitrary bytes.  While they are somewhat REST like, we reserve the right to diverge and
  add more complex operations in the future.

[Protocol buffers](https://developers.google.com/protocol-buffers/) (protos) aren't required to use
gRPC, they are a very convenient way to define service interfaces and generate client and server
code. The generated code acts as glue code between the application logic and the core gRPC
library. We refer to the code called by a gRPC client the _stub_.

## Starting Point

### Client

Now that we know what the program _should_ do, we can start looking at how the program performs.
As mentioned above, the client makes random RPCs.  For example, here is the code that makes the
[creation](https://github.com/carl-mastrangelo/kvstore/blob/f422b1b6e7c69f8c07f96ed4ddba64757242352c/src/main/java/io/grpc/examples/KvClient.java#L80)
request:

```java
private void doCreate(KeyValueServiceBlockingStub stub) {
  ByteString key = createRandomKey();
  try {
    CreateResponse res = stub.create(
        CreateRequest.newBuilder()
            .setKey(key)
            .setValue(randomBytes(MEAN_VALUE_SIZE))
            .build());
    if (!res.equals(CreateResponse.getDefaultInstance())) {
      throw new RuntimeException("Invalid response");
    }
  } catch (StatusRuntimeException e) {
    if (e.getStatus().getCode() == Code.ALREADY_EXISTS) {
      knownKeys.remove(key);
      logger.log(Level.INFO, "Key already existed", e);
    } else {
      throw e;
    }
  }
}
```

A random key is created, along with a random value.  The request is sent to the server, and the
client waits for the response.  When the response is returned, the code checks that it is as
expected, and if not, throws an exception.  While the keys are chosen randomly, they need to be
unique, so we need to make sure that each key isn't already in use.  To address this, the code
keeps track of keys it has created, so as not to create the same key twice.  However, it's
possible that another client already created a particular key, so we log it and move on.
Otherwise, an exception is thrown.

We use the **blocking** gRPC API here, which issues a requests and waits for a response.
This is the simplest gRPC stub, but it blocks the thread while running.  This means that at most
**one** RPC can be in progress at a time from the client's point of view.

### Server

On the server side, the request is received by the
[service handler](https://github.com/carl-mastrangelo/kvstore/blob/f422b1b6e7c69f8c07f96ed4ddba64757242352c/src/main/java/io/grpc/examples/KvService.java#L34):

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

The service extracts the key and value as `ByteBuffer`s from the request.  It acquires the lock
on the service itself to make sure concurrent requests don't corrupt the storage.  After
simulating the disk access of a write, it stores it in the `Map` of keys to values.

Unlike the client code, the service handler is **non-blocking**, meaning it doesn't return a
value like a function call would.  Instead, it invokes `onNext()` on the `responseObserver` to
send the response back to the client.  Note that this call is also non-blocking, meaning that
the message may not yet have been sent.  To indicate we are done with the message, `onCompleted()`
is called.

### Performance

Since the code is safe and correct, let's see how it performs.  For my measurement I'm using my
Ubuntu system with a 12 core processor and 32 GB of memory.  Let's build and run the code:

```sh
./gradlew installDist
time ./build/install/kvstore/bin/kvstore
Feb 26, 2018 1:10:07 PM io.grpc.examples.KvRunner runClient
INFO: Starting
Feb 26, 2018 1:11:07 PM io.grpc.examples.KvRunner runClient
INFO: Did 16.55 RPCs/s

real	1m0.927s
user	0m10.688s
sys	0m1.456s
```

Yikes!  For such a powerful machine, it can only do about 16 RPCs per second.  It hardly used any
of our CPU, and we don't know how much memory it was using.  We need to figure out why it's so
slow.


## Optimization

### Analysis

Let's understand what the program is doing before we make any changes.  When optimizing, we need
to know where the code is spending its time in order to know what we can optimize.  At this early
stage, we don't need profiling tools yet, we can just reason about the program.

The client is started and serially issues RPCs for about a minute.  Each iteration, it [randomly
decides](https://github.com/carl-mastrangelo/kvstore/blob/f422b1b6e7c69f8c07f96ed4ddba64757242352c/src/main/java/io/grpc/examples/KvClient.java#L49)
what operation to do:

```java
void doClientWork(AtomicBoolean done) {
  Random random = new Random();
  KeyValueServiceBlockingStub stub = KeyValueServiceGrpc.newBlockingStub(channel);

  while (!done.get()) {
    // Pick a random CRUD action to take.
    int command = random.nextInt(4);
    if (command == 0) {
      doCreate(stub);
      continue;
    }
    /* ... */
    rpcCount++;
  }
}
```

This means that **at most one RPC can be active at any time**.  Each RPC has to wait for the
previous one to complete.  And how long does each RPC take to complete?  From reading the server
code, most of the operations are doing a write which takes about 50 milliseconds.  At top
efficiency, the most operations this code can do per second is about 20:

20 queries = 1000ms / (50 ms / query)

Our code can do about 16 queries in a second, so that seems about right.  We can spot check this
assumption by looking at the output of the `time` command used to run the code.  The server goes
to sleep when running queries in the
[simulateWork](https://github.com/carl-mastrangelo/kvstore/blob/f422b1b6e7c69f8c07f96ed4ddba64757242352c/src/main/java/io/grpc/examples/KvService.java#L88)
method. This implies that the program should be mostly idle while waiting for the RPCs to
complete.

We can confirm this is the case by looking at the `real` and `user` times of the command above.
They say that the amount of _wall clock_ time was 1 minute, while the amount of _cpu_ time
was 10 seconds.  My powerful, multicore CPU was only busy 16% of the time.  Thus, if we could
get the program to do more work during that time, it seems like we could get more RPCs complete.

### Hypothesis

Now we can state clearly what we think is the problem, and propose a solution.  One way to speed
up programs is to make sure the CPU is not idling.  To do this, we issue work concurrently.

In gRPC Java, there are three types of stubs: blocking, non-blocking, and listenable future.  We
have already seen the blocking stub in the client, and the non-blocking stub in the server.  The
listenable future API is a compromise between the two, offering both blocking and non-blocking
like behavior.  As long as we don't block a thread waiting for work to complete, we can start
new RPCs without waiting for the old ones to complete.

### Experiment

To test our hypothesis, let's modify the client code to use the listenable future API.  This
means that we need to think more about concurrency in our code.  For example, when keeping track
of known keys client-side, we need to safely read, modify, and write the keys.  We also need to
make sure that in case of an error, we stop making new RPCs (proper error handling will be covered
in a future post).  Lastly, we need to update the number of RPCs made concurrently, since the
update could happen in another thread.

Making all these changes increases the complexity of the code.  This is a trade off you will need
to consider when optimizing your code.  In general, code simplicity is at odds with optimization.
Java is not known for being terse.  That said, the code below is still readable, and program flow
is still roughly from top to bottom in the function.  Here is the
[doCreate()](https://github.com/carl-mastrangelo/kvstore/blob/f0113912c01ac4ea48a80bb7a4736ddcb3f21e24/src/main/java/io/grpc/examples/KvClient.java#L92)
method revised:

```java
private void doCreate(KeyValueServiceFutureStub stub, AtomicReference<Throwable> error) {
  ByteString key = createRandomKey();
  ListenableFuture<CreateResponse> res = stub.create(
      CreateRequest.newBuilder()
          .setKey(key)
          .setValue(randomBytes(MEAN_VALUE_SIZE))
          .build());
  res.addListener(() -> rpcCount.incrementAndGet(), MoreExecutors.directExecutor());
  Futures.addCallback(res, new FutureCallback<CreateResponse>() {
    @Override
    public void onSuccess(CreateResponse result) {
      if (!result.equals(CreateResponse.getDefaultInstance())) {
        error.compareAndSet(null, new RuntimeException("Invalid response"));
      }
      synchronized (knownKeys) {
        knownKeys.add(key);
      }
    }

    @Override
    public void onFailure(Throwable t) {
      Status status = Status.fromThrowable(t);
      if (status.getCode() == Code.ALREADY_EXISTS) {
        synchronized (knownKeys) {
          knownKeys.remove(key);
        }
        logger.log(Level.INFO, "Key already existed", t);
      } else {
        error.compareAndSet(null, t);
      }
    }
  });
}
```

The stub has been modified to be a `KeyValueServiceFutureStub`, which produces a `Future` when
called instead of the response itself.  gRPC Java uses an extension of this called `ListenableFuture`,
which allows adding a callback when the future completes.  For the sake of this program, we are
not as concerned with getting the response.  Instead we care more if the RPC succeeded or not.
With that in mind, the code mainly checks for errors rather than processing the response.

The first change made is how the number of RPCs is recorded.  Instead of incrementing the counter
outside of the main loop, we increment it when the RPC completes.

Next, we create a new object
for each RPC which handles both the success and failure cases.  Because `doCreate()` will already
be completed by the time RPC callback is invoked, we need a way to propagate errors other than
by throwing.  Instead, we try to update an reference atomically.  The main loop will occasionally
check if an error has occurred and stop if there is a problem.

Lastly, the code is careful to only add a key to `knownKeys` when the RPC is actually complete,
and only remove it when known to have failed.  We synchronize on the variable to make sure two
threads don't conflict.  Note: although the access to `knownKeys` is threadsafe, there are still
[race conditions](https://en.wikipedia.org/wiki/Race_condition).  It is possible that one thread
could read from `knownKeys`, a second thread delete from `knownKeys`, and then the first thread
issue an RPC using the first key.  Synchronizing on the keys only ensures that it is consistent,
not that it is correct.  Fixing this properly is outside of the scope of this post, so instead we
just log the event and move on.  You will see a few such log statements if you run this program.

### Running the Code

If you start up this program and run it, you'll notice that it doesn't work:

```sh
WARNING: An exception was thrown by io.grpc.netty.NettyClientStream$Sink$1.operationComplete()
java.lang.OutOfMemoryError: unable to create new native thread
	at java.lang.Thread.start0(Native Method)
	at java.lang.Thread.start(Thread.java:714)
	...
```

What?!  Why would I show you code that fails?  The reason is that in real life making a change often
doesn't work on the first try.  In this case, the program ran out of memory.  Odd things begin to
happen when a program runs out of memory.  Often, the root cause is hard to find, and red herrings
abound.  A confusing error message says "unable to create new native thread"
even though we didn't create any new threads in our code.  Experience is very helpful in fixing
these problems rather than debugging.  Since I have debugged many OOMs, I happen to know Java tells
us about the straw that broke the camel's back.  Our program started using way more memory, but the
final allocation that failed happened, by chance, to be in thread creation.

So what happened?  _There was no pushback to starting new RPCs._  In the blocking version, a new
RPC couldn't start until the last one completed.  While slow, it also prevented us from creating
tons of RPCs that we didn't have memory for.  We need to account for this in the listenable
future version.

To solve this, we can apply a self-imposed limit on the number of active RPCs.  Before starting a
new RPC, we will try to acquire a permit.  If we get one, the RPC can start.  If not, we will wait
until one is available.  When an RPC completes (either in success or failure), we return the
permit.  To [accomplish](https://github.com/carl-mastrangelo/kvstore/blob/02-future-client/src/main/java/io/grpc/examples/KvClient.java#L94)
this, we will using a `Semaphore`:

```java
private final Semaphore limiter = new Semaphore(100);

private void doCreate(KeyValueServiceFutureStub stub, AtomicReference<Throwable> error)
    throws InterruptedException {
  limiter.acquire();
  ByteString key = createRandomKey();
  ListenableFuture<CreateResponse> res = stub.create(
      CreateRequest.newBuilder()
          .setKey(key)
          .setValue(randomBytes(MEAN_VALUE_SIZE))
          .build());
  res.addListener(() ->  {
    rpcCount.incrementAndGet();
    limiter.release();
  }, MoreExecutors.directExecutor());
  /* ... */
}
```

Now the code runs successfully, and doesn't run out of memory.

### Results

Building and running the code again looks a lot better:

```sh
./gradlew installDist
time ./build/install/kvstore/bin/kvstore
Feb 26, 2018 2:40:47 PM io.grpc.examples.KvRunner runClient
INFO: Starting
Feb 26, 2018 2:41:47 PM io.grpc.examples.KvRunner runClient
INFO: Did 24.283 RPCs/s

real	1m0.923s
user	0m12.772s
sys	0m1.572s
```

Our code does **46%** more RPCs per second than previously.  We can also see that we used about 20%
more CPU than previously.  As we can see our hypothesis turned out to be correct and the fix
worked.  All this happened without making any changes to the server.  Also, we were able to
measure without using any special profilers or tracers.

Do the numbers make sense?  We expect to issue mutation (create, update, and delete) RPCs each
about with 1/4 probability.  Reads are also issue 1/4 of the time, but don't take as long.  The
mean RPC time should be about the weighted average RPC time:

```nocode
  .25 * 50ms (create)
  .25 * 10ms (retrieve)
  .25 * 50ms (update)
 +.25 * 50ms (delete)
------------
        40ms
```

At 40ms on average per RPC, we would expect the number of RPCs per second to be:

25 queries = 1000ms / (40 ms / query)

That's approximately what we see with the new code.  The server is still serially handling
requests, so it seems like we have more work to do in the future.  But for now, our optimizations
seem to have worked.


## Conclusion

There are a lot of opportunities to optimize your gRPC code.  To take advantage of these, you
need to understand what your code is doing, and what your code is supposed to do.  This post shows
the very basics of how to approach and think about optimization.  Always make sure to measure
before and after your changes, and use these measurements to guide your optimizations.

In [Part 2](/blog/optimizing-grpc-part-2/), we will continue optimizing the server part of the code.
