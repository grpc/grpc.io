---
title: gRPC-Rust Client API Evolution (pt. 2/2)
date: 2026-06-01
spelling: cSpell:ignore Tokio
author:
  name: Doug Fawley
  position: Google
---

### PART 2

*The following is part 2 of a 2-part series.  Please see [part
1](../grpc-rust-client-api-1) for additional background.*

# Channel API

In the previous blog post, we established a target for our generated code API,
so now let's focus on the channel API that powers it.  From part 1, you'll
remember that in gRPC, the
[channel](https://grpc.io/docs/what-is-grpc/core-concepts/#channels) is the main
client entry point.  Unlike the generated API, this one treats all RPCs as
streaming to unify the implementation at this level.  **Most users will not
interact with this API directly.**  Instead, the generated code will use it on
the application's behalf.  It will only be needed if you are building
interceptors or performing RPCs without any code generation.

## Should be a Trait

Similar to tower, if the generic API is built with a trait, then you can
implement interceptors by wrapping the generic API with your own implementation.
Ideally this would be a zero-cost abstraction (no dynamic dispatch between
layers) so that we can efficiently implement all our internal features like
retries and compression through this API as well.

## Use Generic Type Parameters for Messages?

Tower and Tonic use generic types for messages.  Reasons to prefer generics over
dynamic dispatch include:

1. Avoids vtable lookups of the message encoder/decoder on every send and
   receive operation.
2. Dynamic types, due to their lack of a fixed size, typically involve a heap
   allocation (e.g. via `Box`).
3. Static type safety, which guarantees all messages (requests & responses) on a
   stream are the proper type.

However, generics can cause longer compile times and more code output if you
plumb the generics all the way down to the point where (de)serialization happens
\-- and if you don't, then you bear the cost of the vtable lookup anyway, so
you've completely lost the marginal performance benefit from (1).

Additionally, we can use dynamic types but avoid the heap allocations mentioned
in (2) by passing references to dynamic message types instead of owned, `Box`ed
objects, e.g.

```rust
fn next_response_message(dest: &mut dyn ResponseMessage)
```

And finally, (3) is not a significant need for this style of API, since the API
the application interacts with most is fully type-safe already.

In the end, we decided against the use of generics for message types, in favor
of dynamic type references, as the costs outweighed the benefits.

## Use a Stream Object?

One naive approach would be to provide a `Stream` type representing an in-flight
RPC that the application can interact with.  This is what gRPC-Go does, but it
causes a small problem: while `SendMsg` and `RecvMsg` can be called
concurrently, we don't want to allow multiple sends or receives at the same
time.  Also, we'll want to perform these operations from independent tasks,
meaning it would need to support cloning, which incurs additional
synchronization costs.

## Construction like [mpsc::channel](https://doc.rust-lang.org/std/sync/mpsc/fn.channel.html)?

To solve the concurrent operations problem, I decided to try splitting the
stream into two halves: one for sending and one for receiving, similar to a
channel or splitting a `tokio::net::TcpStream` into owned read and write halves
using `into_split`.  This would look something like this:

```rust
// Definition:
pub trait Service {
    async fn call(&mut self) -> (impl SendStream, impl RecvStream)
}

pub trait SendStream { /* send method */ }
pub trait RecvStream { /* recv method */ }

// Usage:
async fn main() {
    let (mut tx, mut rx) = channel.call(...).await;
    tx.send(&request).await;
    rx.recv(&response).await;
}
```

This feels natural and works well.  The application can allocate request and
response messages and pass them to the appropriate stream, meaning it can
support the arena allocations we needed.

However, the usage of
[RPITIT](https://rustc-dev-guide.rust-lang.org/return-position-impl-trait-in-trait.html)
(Return Position Impl Trait In Trait) turns out to be a problem for this
implementation: to support retries in an interceptor layer, we will need to
store the delegate streams in wrappers, send them on channels, etc.  But with
`impl Trait`, the returned types are anonymous, so even though you have a stable
stream creator as your delegate, you can't get two stream instances from it and
store them in the same memory.  E.g.

```rust
fn call(...) -> (impl SendStream, impl RecvStream) {
    let (mut tx, mut rx) = delegate.call(...).await;
    let wtx = WrappedStream::new(tx); // What type is this?  WrappedStream<???>?
    return (wtx, rx);
}
```

In this example, when `wtx` needs to be updated to have a new delegate
`SendStream` in it, you can't assign it even if you know it was created by the
same delegate and that the types do match.

Another thing to watch out for with RPIT: the returned types implicitly capture
the lifetime of the `&self` receiver.  For our design, we would need them to be
`'static` so they can be sent to other tasks.  This *can* be achieved with RPIT
using [`use<..>
clauses`](https://doc.rust-lang.org/edition-guide/rust-2024/rpit-lifetime-capture.html)
to control the lifetime capturing, but that would make the API more complicated.

## Associated Types Instead of RPITIT

The obvious fix for both RPITIT problems is to declare associated types for the
returned streams:

```rust
pub trait Service {
    type RequestStream: SendStream + 'static;
    type ResponseStream: RecvStream + 'static;
    async fn call(...) -> (Self::RequestStream, Self::ResponseStream);
}
```

With this change, now the types can be named, meaning we can store them in
structs with named type parameters, and we can update them for retry attempts.
And since they are `'static`, they cannot capture the lifetime of `&self`.
Indeed, this is the final implementation:

```rust
pub trait Invoke: Sync {
    type SendStream: SendStream + 'static;
    type RecvStream: RecvStream + 'static;

    async fn invoke(
        &self,
        headers: RequestHeaders,
        options: CallOptions,
    ) -> (Self::SendStream, Self::RecvStream);
}
```

You may also have noticed the names have changed.  Naming things is known to be
the hardest problem in computer science, and this was no exception.  I wanted to
avoid `Service::call` since that is what Tower uses, and the semantics here are
different.  "Invoke" captures the same intent as "call", and is less-used as a
general programming term, so it felt like a good choice.

## Interceptor Complications

With Rust's strict ownership model, we have a special scenario we need to
consider for interceptors.  In order to allow applications to receive the
metadata from a call in a convenient way, we'd like to be able to apply an
interceptor that holds a one-shot channel ([e.g. from
Tokio](https://docs.rs/tokio/latest/tokio/sync/oneshot/index.html)) that sends
the metadata to the application upon receipt.  One-shot `Sender`s are consumed
upon their use, so we'd like to design our interceptors so that they may have a
"once" variant as well as a reusable version.  Because of different usage
patterns and how we might want to stack interceptors, this distinction
unfortunately results in *four* different kinds of interceptors:

| Interceptor type | Delegate Use? | Reusable? | Examples | What to implement |
| :---- | :---- | :---- | :---- | :---- |
| Basic | one-time | yes | Logging, Validation | `Intercept<InvokeOnce>` |
| Once | one-time | no | Metadata accessor | `InterceptOnce<InvokeOnce>` |
| Retryable | multiple | yes | Retry | `Intercept<Invoke + Clone + 'static>` |
| RetryableOnce | multiple | no | ?? | `InterceptOnce<Invoke + Clone + 'static>` |

(The `+ Clone + 'static` bounds are optional and unnecessary if you only call
`invoke` directly and do not need the additional functionality that those bounds
would provide.)

As you can probably tell, you can't combine these in any way you'd like \--
"retryable" interceptors cannot be wrapped around "once" interceptors, but we
would like to be able to wrap a "basic" interceptor around a "once" interceptor.
The
[`grpc::client::interceptor`](https://docs.rs/grpc/latest/grpc/client/interceptor/index.html)
module implements all of this functionality, and in an easy-to-use way.  To add
interceptors around an `Invoke` or `InvokeOnce` implementation, you just need to
know whether they implement `Intercept` or `InterceptOnce`.  Then you can take
advantage of the
[`InvokeExt`](https://docs.rs/grpc/latest/grpc/client/interceptor/trait.InvokeExt.html)
and
[`InvokeOnceExt`](https://docs.rs/grpc/latest/grpc/client/interceptor/trait.InvokeOnceExt.html)
extension traits to chain them using `with_interceptor` or
`with_once_interceptor`, yielding you a new `Invoke` or `InvokeOnce`
implementation that contains the combination.

## Done?

And that's it\!  This is the API we released in this preview.  We are still open
to making further changes and look forward to hearing your feedback, whether it
is positive or negative.
