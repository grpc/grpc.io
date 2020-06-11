---
title: Interceptors in gRPC-Web
date: 2020-06-11
authors:
- name: Zhenli Jiang
  position: Google
---

We're pleased to announce support for _interceptors_ in [gRPC-web][] as of
release [1.1.0][]. While the current design is based on gRPC client interceptors
available from other [gRPC languages][], it also includes gRPC-web specific
features that should make interceptors easy to adopt and use alongside modern
web frameworks.

## Introduction

Similar to other gRPC languages, gRPC-web supports _unary_ and server
_streaming_ interceptors. For each kind of interceptor, we've [defined an
interface][interceptor.js] containing a single `intercept()` method:

- `UnaryInterceptor`
- `StreamInterceptor`

For example, the `UnaryInterceptor` interface is declared like this:

```js
/*
* @interface
*/
const UnaryInterceptor = function() {};

/**
 * @template REQUEST, RESPONSE
 * @param {!Request<REQUEST, RESPONSE>} request
 * @param {function(!Request<REQUEST,RESPONSE>):!Promise<!UnaryResponse<RESPONSE>>}
 *     invoker
 * @return {!Promise<!UnaryResponse<RESPONSE>>}
 */
UnaryInterceptor.prototype.intercept = function(request, invoker) {};
```

The `intercept()` method takes two parameters:

- A `request` of type [grpc.web.Request][]
- An `invoker`, which performs the actual RPC when invoked

The `StreamInterceptor` interface declaration is similar, except that the
`invoker` return type is `ClientReadablaStream` instead of `Promise`. For
implementation details, see [interceptor.js][].

## What can I do with an interceptor?

Basically, an interceptor allows you to do the following:

- Update the original gRPC request before it is passed along. For example, you
  might inject extra information such as auth headers.
- Manipulate the behavior of the original invoker function, such as bypassing
  the call or updating the response before it is returned to the client.

Some examples are given next.

## Unary interceptor example

The code given below illustrates a unary interceptor that does the following:

- It prepends a string to the gRPC request message before the RPC.
- It prepends a string to the gRPC response message after it is received.

This simple unary interceptor is defined as class that implements the
`UnaryInterceptor` interface:

```js
/**
 * @constructor
 * @implements {UnaryInterceptor}
 */
const SimpleUnaryInterceptor = function() {};

/** @override */
SimpleUnaryInterceptor.prototype.intercept = function(request, invoker) {
  // Update the request message before the RPC.
  const reqMsg = request.getRequestMessage();
  reqMsg.setMessage('[Intercept request]' + reqMsg.getMessage());

  // After the RPC returns successfully, update the response.
  return invoker(request).then((response) => {
    // We could also do something with response metadata here.
    console.log(response.getMetadata());

    // Update the response message.
    const responseMsg = response.getResponseMessage();
    responseMsg.setMessage('[Intercept response]' + responseMsg.getMessage());

    return response;
  });
};
```

## Stream interceptor example

More care is needed to intercept server streamed responses from a
`ClientReadableStream` using a `StreamInterceptor`. These are the main steps to
follow:

 1. Create a `ClientReadableStream`-wrapper class used to intercept stream
    events such as the reception of responses.
 2. Create a class that implements `StreamInterceptor` and uses the stream wrapper.

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
const InterceptedStream = function(stream) {
  this.stream = stream;
};

/** @override */
InterceptedStream.prototype.on = function(eventType, callback) {
  if (eventType == 'data') {
    const newCallback = (response) => {
      // Update the response message.
      const msg = response.getMessage();
      response.setMessage('[Intercept response]' + msg);
      // Pass along the updated response.
      callback(response);
    };
    // Register the new callback.
    this.stream.on(eventType, newCallback);
  } else {
    // We could also override 'status', 'end', 'error' eventTypes.
    this.stream.on(eventType, callback);
  }
  return this;
};

/** @override */
InterceptedStream.prototype.cancel = function() {
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
const TestStreamInterceptor = function() {};

/** @override */
TestStreamInterceptor.prototype.intercept = function(request, invoker) {
  return new InterceptedStream(invoker(request));
};
```

## Binding interceptors

By passing an array of inteceptor instances using an appropriate option key,
you can bind interceptors to a client when the client is instantiated:

```js
const promiseClient = new FooServicePromiseClient(
    host, creds, {'unaryInterceptors': [interceptor1, interceptor2, interceptor3]});

const client = new FooServiceClient(
    host, creds, {'streamInterceptors': [interceptor1, interceptor2, interceptor3]});
```

{{< note >}}
  Interceptors are executed in reverse order for request processing, and in order for response processing:

  ```nocode
  Request  --> interceptor3  --> interceptor2  --> interceptor1 --> Intercepted --> Server
                                                                    request           |
                                                                                      |
  Intercepted <-- interceptor3 <-- interceptor2 <-- interceptor1 <--   Response  <-- Server
  response
  ```
{{< /note >}}

### Advanced example: RetryInterceptor

```js
/**
 * @constructor
 * @implements {StreamInterceptor}
 */
const RetryInterceptor = function() {};

/** @override */
RetryInterceptor.prototype.intercept = function(request, invoker) {
  /**
   * @implements {ClientReadableStream}
   * @constructor
   * @param {!ClientReadableStream<RESPONSE>} stream
   * @param {number} retries
   * @template RESPONSE
   */
  const InterceptedStream = function(stream, retries) {
    this.stream = stream;
    this.retries = retries;
    this.onDataCallback = null;
  };

  /** @override */
  InterceptedStream.prototype.on = function(eventType, callback) {
    if (eventType == 'data') {
      this.onDataCallback_ = callback;
      this.stream.on(eventType, callback);
    } else if (eventType == 'status') {
      const newCallback = (status) => {
        if (this.retries > 0 && status !== StatusCode.OK) {
          const reqMessage = request.getRequestMessage();
          reqMessage.setMessage(`[Retry ${this.retries}]`);
          this.stream.cancel();
          this.stream =
              new InterceptedStream(invoker(request), this.retries - 1);
          this.stream.on('status', callback);
          if (this.onDataCallback_) {
            // Set up the new callback for the new stream.
            this.stream.on('data', this.onDataCallback_);
          }
        } else {
          callback(status);
        }
      };
      this.stream.on(eventType, newCallback);
    }
    return this;
  };

  /** @override */
  InterceptedStream.prototype.cancel = function() {
    this.stream.cancel();
    return this;
  };

  return new InterceptedStream(invoker(request), 3);
};
```

## Feedback

Found a problem with `grpc-web` or need a feature? File an [issue][] over the
[grpc-web][] repository. If you have general questions or comments, then
consider posting to the [gRPC mailing list][] or sending an email to
[grpc-web-team@google.com][].

[1.1.0]: https://github.com/grpc/grpc-web/releases/tag/1.1.0
[gRPC languages]: /docs/languages
[gRPC mailing list]: https://groups.google.com/forum/#!forum/grpc-io
[grpc-web-team@google.com]: mailto:grpc-web-team@google.com
[grpc-web]: https://github.com/grpc/grpc-web
[grpc.web.Request]: https://github.com/grpc/grpc-web/blob/master/javascript/net/grpc/web/request.js
[interceptor.js]: https://github.com/grpc/grpc-web/blob/master/javascript/net/grpc/web/interceptor.js
[issue]: https://github.com/grpc/grpc-web/issues/new
