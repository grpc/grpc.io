---
title: OAuth2
weight: 60
---

This example demonstrates how to use OAuth2 on gRPC to make
authenticated API calls on behalf of a user.

By walking through it you'll also learn how to use the Objective-C gRPC API to:

- Initialize and configure a remote call object before the RPC is started.
- Set request metadata elements on a call, which are semantically equivalent to
  HTTP request headers.
- Read response metadata from a call, which is equivalent to HTTP response
  headers and trailers.

It assumes you know the basics on how to make gRPC API calls using the
Objective-C client library, as shown in [Basics tutorial](../basics/) and the
[Introduction to gRPC](/docs/what-is-grpc/introduction/), and are familiar with OAuth2 concepts like _access
token_.

### Example code and setup {#setup}

For the example source, see [gprc/examples/objective-c/auth_sample][]. To
download the example, clone this repository by running the following commands:

```sh
git clone -b {{< param grpc_vers.core >}} --depth 1 --shallow-submodules https://github.com/grpc/grpc
cd grpc
git submodule update --init
```

Then change your current directory to `examples/objective-c/auth_sample`:

```sh
cd examples/objective-c/auth_sample
```

Our example is a simple application with two views. The first view lets a user
sign in and out using the OAuth2 flow of Google's [iOS SignIn
library](https://developers.google.com/identity/sign-in/ios/). (Google's library
is used in this example because the test gRPC service we are going to call
expects Google account credentials, but neither gRPC nor the Objective-C client
library is tied to any specific OAuth2 provider). The second view makes a gRPC
request to the test server, using the access token obtained by the first view.

{{% alert title="Note" color="info" %}}
OAuth2 libraries need the application to register and obtain an ID from
the identity provider (in the case of this example app, Google). The app's XCode
project is configured using that ID, so you shouldn't copy this project "as is"
for your own app: it would result in your app being identified in the consent
screen as "gRPC-AuthSample", and not having access to real Google services.
Instead, configure your own XCode project following the [instructions
here](https://developers.google.com/identity/sign-in/ios/).
{{% /alert %}}

As with the other Objective-C examples, you also should have
[CocoaPods](https://cocoapods.org/#install) installed, as well as the relevant
tools to generate the client library code. You can obtain the latter by
following [these setup instructions](https://github.com/grpc/homebrew-grpc).

### Try it out! {#try}

To try the sample app, first have CocoaPods generate and install the client library for our .proto
files:

```sh
pod install
```

(This might have to compile OpenSSL, which takes around 15 minutes if CocoaPods
doesn't have it yet on your computer's cache).

Finally, open the XCode workspace created by CocoaPods, and run the app.

The first view, `SelectUserViewController.h/m`, asks you to sign in with your
Google account, and to give the "gRPC-AuthSample" app the following permissions:

- View your email address.
- View your basic profile info.
- "Test scope for access to the Zoo service".

This last permission, corresponding to the scope
`https://www.googleapis.com/auth/xapi.zoo` doesn't grant any real capability:
it's only used for testing. You can log out at any time.

The second view, `MakeRPCViewController.h/m`, makes a gRPC request to a test
server at https://grpc-test.sandbox.google.com, sending the access token along
with the request. The test service simply validates the token and writes in its
response which user it belongs to, and which scopes it gives access to. (The
client application already knows those two values; it's a way to verify that
everything went as expected).

The next sections guide you step-by-step through how the gRPC call in
`MakeRPCViewController` is performed. You can see the complete code in
[MakeRPCViewController.m](https://github.com/grpc/grpc/blob/{{< param grpc_vers.core >}}/examples/objective-c/auth_sample/MakeRPCViewController.m).

### Create a call with access token {#rpc-call}

To make an authenticated call, first you need to initialize a `GRPCCallOptions` object and configure
it with the access token.

```objective-c
GRPCMutableCallOptions *options = [[GRPCMutableCallOptions alloc] init];
options.oauth2AccessToken = myAccessToken;
```

Then you need to create and start your call with this call options object. Assume you have a proto
service definition like this:

```protobuf
option objc_class_prefix = "AUTH";

service TestService {
  rpc UnaryCall(Request) returns (Response);
}
```

A `unaryCallWithMessage:responseHandler:callOptions:` method, with which you're already familiar, is
generated for the `AUTHTestService` class:

```objective-c
- (GRPCUnaryProtoRPC *)unaryCallWithMessage:(AUTHRequest *)message
                            responseHandler:(id<GRPCProtoResponseHandler>)responseHandler
                                callOptions:(GRPCCallOptions *)callOptions;
```

Use this method to generated the RPC object with your request options object:

```objective-c
GRPCUnaryProtoRPC *rpc = [client unaryCallWithMessage:myRequestMessage
                                      responseHandler:myResponseHandler
                                          callOptions:options];
```

You can then start the RPC represented by this object at any later time like this:

```objective-c
[rpc start];
```

### An alternative way to provide access token {#authorization-protocol}

Rather than setting `oauth2AccessToken` option in `GRPCCallOptions` before the RPC object is
created, an alternative approach allows users providing access token at call start time.

To use this approach, first create a class in your project that conforms to
`GRPCAuthorizationProtocol` protocol.

```objective-c
@interface TokenProvider : NSObject<GRPCAuthorizationProtocol>
...
@end

@implementation TokenProvider

- (void)getTokenWithHandler:(void (^)(NSString* token))handler {
  ...
}

@end
```

When creating an RPC object, pass an instance of this class to call option `authTokenProvider`:

```objective-c
GRPCMutableCallOptions *options = [[GRPCMutableCallOptions alloc] init];
options.authTokenProvider = [[TokenProvider alloc] init];
GRPCUnaryProtoCall *rpc = [client unaryCallWithMessage:myRequestMessage
                                       responseHandler:myResponseHandler
                                           callOptions:options] start];
[rpc start];
```

When the call starts, it will call the `TokenProvider` instance's `getTokenWithHandler:` method with
a callback `handler` and waits for the callback. The `TokenProvider` instance may call the handler
at any time to provide the token for this call and resume the call process.

[gprc/examples/objective-c/auth_sample]: https://github.com/grpc/grpc/tree/{{< param grpc_vers.core >}}/examples/objective-c/auth_sample
