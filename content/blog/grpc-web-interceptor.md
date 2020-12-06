---
title: Interceptors in gRPC-Web
date: 2020-06-18
spelling: cSpell:ignore creds Jiang Zhenli
author: { name: Zhenli Jiang, position: Google }
---

We're pleased to announce support for _interceptors_ in [gRPC-web][] as of
release [1.1.0][]. While the current design is based on gRPC client interceptors
available from other [gRPC languages][], it also includes gRPC-web specific
features that should make interceptors easy to adopt and use alongside modern
web frameworks.

## Introduction

Similar to other gRPC languages, gRPC-web supports _unary_ and
server-_streaming_ interceptors. For each kind of interceptor, we've [defined an
interface][interceptor.js] containing a single `intercept()` method:

- `UnaryInterceptor`
- `StreamInterceptor`

This is how the `UnaryInterceptor` interface is declared:

```js
/*
 * @interface
 */
const UnaryInterceptor = function () {};

/**
 * @template REQUEST, RESPONSE
 * @param {!Request<REQUEST, RESPONSE>} request
 * @param {function(!Request<REQUEST,RESPONSE>):!Promise<!UnaryResponse<RESPONSE>>}
 *     invoker
 * @return {!Promise<!UnaryResponse<RESPONSE>>}
 */
UnaryInterceptor.prototype.intercept = function (request, invoker) {};
```

The `intercept()` method takes two parameters:

- A `request` of type [grpc.web.Request][]
- An `invoker`, which performs the actual RPC when invoked

The `StreamInterceptor` interface declaration is similar, except that the
`invoker` return type is `ClientReadableStream` instead of `Promise`. For
implementation details, see [interceptor.js][].

{{< alert title="Note" color="info" >}}
A `StreamInterceptor` can be applied to any RPC with a `ClientReadableStream`
return type, whether it's a unary or a server-streaming RPC.
{{< /alert >}}

## What can I do with an interceptor?

An interceptor allows you to do the following:

- Update the original gRPC request before passing it along &mdash; for
  example, you might inject extra information such as auth headers
- Manipulate the behavior of the original invoker function, such as bypassing
  the call so that you can use a cached result instead
- Update the response before it's returned to the client

You'll see some examples next.

## Unary interceptor example

The code given below illustrates a unary interceptor that does the following:

- It prepends a string to the gRPC request message before the RPC.
- It prepends a string to the gRPC response message after it's received.

This simple unary interceptor is defined as a class that implements the
`UnaryInterceptor` interface:

```js
/**
 * @constructor
 * @implements {UnaryInterceptor}
 */
const SimpleUnaryInterceptor = function () {};

/** @override */
SimpleUnaryInterceptor.prototype.intercept = function (request, invoker) {
  // Update the request message before the RPC.
  const reqMsg = request.getRequestMessage();
  reqMsg.setMessage("[Intercept request]" + reqMsg.getMessage());

  // After the RPC returns successfully, update the response.
  return invoker(request).then((response) => {
    // You can also do something with response metadata here.
    console.log(response.getMetadata());

    // Update the response message.
    const responseMsg = response.getResponseMessage();
    responseMsg.setMessage("[Intercept response]" + responseMsg.getMessage());

    return response;
  });
};
```

## Stream interceptor example

More care is needed to intercept server-streamed responses from a
`ClientReadableStream` using a `StreamInterceptor`. These are the main steps to
follow:

1.  Create a `ClientReadableStream`-wrapper class, and use it to intercept
    stream events such as the reception of server responses.
2.  Create a class that implements `StreamInterceptor` and that uses the stream
    wrapper.

The following sample stream-wrapper class intercepts responses and prepends a
string to response messages:

```js
/**
 * A ClientReadableStream wrapper.
 *
 * @template RESPONSE
 * @implements {ClientReadableStream}
 * @constructor
 * @param {!ClientReadableStream<RESPONSE>} stream
 */
const InterceptedStream = function (stream) {
  this.stream = stream;
};

/** @override */
InterceptedStream.prototype.on = function (eventType, callback) {
  if (eventType == "data") {
    const newCallback = (response) => {
      // Update the response message.
      const msg = response.getMessage();
      response.setMessage("[Intercept response]" + msg);
      // Pass along the updated response.
      callback(response);
    };
    // Register the new callback.
    this.stream.on(eventType, newCallback);
  } else {
    // You can also override 'status', 'end', and 'error' eventTypes.
    this.stream.on(eventType, callback);
  }
  return this;
};

/** @override */
InterceptedStream.prototype.cancel = function () {
  this.stream.cancel();
  return this;
};
```

The `intercept()` method of the sample interceptor returns a wrapped stream:

```js
/**
 * @constructor
 * @implements {StreamInterceptor}
 */
const TestStreamInterceptor = function () {};

/** @override */
TestStreamInterceptor.prototype.intercept = function (request, invoker) {
  return new InterceptedStream(invoker(request));
};
```

## Binding interceptors

By passing an array of interceptor instances using an appropriate option key,
you can bind interceptors to a client when the client is instantiated:

```js
const promiseClient = new MyServicePromiseClient(host, creds, {
  unaryInterceptors: [interceptor1, interceptor2, interceptor3],
});

const client = new MyServiceClient(host, creds, {
  streamInterceptors: [interceptor1, interceptor2, interceptor3],
});
```

{{< alert title="Note" color="info" >}}
Interceptors are executed in reverse order for request processing, and in
order for response processing, as illustrated here:

![Interceptor processing order](/img/grpc-web-interceptors.png)
{{< /alert >}}

## Feedback

Found a problem with `grpc-web` or need a feature? File an [issue][] over the
[grpc-web][] repository. If you have general questions or comments, then
consider posting to the [gRPC mailing list][] or sending us an email at
[grpc-web-team@google.com][].

[1.1.0]: https://github.com/grpc/grpc-web/releases/tag/1.1.0
[grpc languages]: /docs/languages/
[grpc mailing list]: https://groups.google.com/forum/#!forum/grpc-io
[grpc-web-team@google.com]: mailto:grpc-web-team@google.com
[grpc-web]: https://github.com/grpc/grpc-web
[grpc.web.request]: https://github.com/grpc/grpc-web/blob/master/javascript/net/grpc/web/request.js
[interceptor.js]: https://github.com/grpc/grpc-web/blob/master/javascript/net/grpc/web/interceptor.js
[issue]: https://github.com/grpc/grpc-web/issues/new
