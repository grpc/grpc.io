---
title: Authentication
description: >-
  An overview of gRPC authentication, including built-in auth mechanisms, and
  how to plug in your own authentication systems.
---

### Overview

gRPC is designed to work with a variety of authentication mechanisms, making it
easy to safely use gRPC to talk to other systems. You can use our supported
mechanisms - SSL/TLS with or without Google token-based authentication - or you
can plug in your own authentication system by extending our provided code.

gRPC also provides a simple authentication API that lets you provide all the
necessary authentication information as `Credentials` when creating a channel or
making a call.

### Supported auth mechanisms

The following authentication mechanisms are built-in to gRPC:

- **SSL/TLS**: gRPC has SSL/TLS integration and promotes the use of SSL/TLS
  to authenticate the server, and to encrypt all the data exchanged between
  the client and the server. Optional mechanisms are available for clients to
  provide certificates for mutual authentication.
- **ALTS**: gRPC supports
  [ALTS](https://cloud.google.com/security/encryption-in-transit/application-layer-transport-security)
  as a transport security mechanism, if the application is running on
  [Compute Engine](https://cloud.google.com/compute) or
  [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine).
  For details, see one of the following
  language-specific pages:
  [ALTS in C++]({{< relref "docs/languages/cpp/alts" >}}),
  [ALTS in Go]({{< relref "docs/languages/go/alts" >}}),
  [ALTS in Java]({{< relref "docs/languages/java/alts" >}}),
  [ALTS in Python]({{< relref "docs/languages/python/alts" >}}).
- **Token-based authentication with Google**: gRPC provides a generic
  mechanism (described below) to attach metadata based credentials to requests
  and responses. Additional support for acquiring access tokens
  (typically OAuth2 tokens) while accessing Google APIs through gRPC is
  provided for certain auth flows: you can see how this works in our code
  examples below. In general this mechanism must be used *as well as* SSL/TLS
  on the channel - Google will not allow connections without SSL/TLS, and
  most gRPC language implementations will not let you send credentials on an
  unencrypted channel.

{{% alert title="Warning" color="warning" %}}
  Google credentials should only be used to connect to Google services. Sending
  a Google issued OAuth2 token to a non-Google service could result in this
  token being stolen and used to impersonate the client to Google services.
{{% /alert %}}

### Authentication API

gRPC provides a simple authentication API based around the unified concept of
Credentials objects, which can be used when creating an entire gRPC channel or
an individual call.

#### Credential types

Credentials can be of two types:

- **Channel credentials**, which are attached to a `Channel`, such as SSL
  credentials.
- **Call credentials**, which are attached to a call (or `ClientContext` in
  C++).

You can also combine these in a `CompositeChannelCredentials`, allowing you to
specify, for example, SSL details for the channel along with call credentials
for each call made on the channel. A `CompositeChannelCredentials` associates a
`ChannelCredentials` and a `CallCredentials` to create a new
`ChannelCredentials`. The result will send the authentication data associated
with the composed `CallCredentials` with every call made on the channel.

For example, you could create a `ChannelCredentials` from an `SslCredentials`
and an `AccessTokenCredentials`. The result when applied to a `Channel` would
send the appropriate access token for each call on this channel.

Individual `CallCredentials` can also be composed using
`CompositeCallCredentials`. The resulting `CallCredentials` when used in a call
will trigger the sending of the authentication data associated with the two
`CallCredentials`.


#### Using client-side SSL/TLS

Now let's look at how `Credentials` work with one of our supported auth
mechanisms. This is the simplest authentication scenario, where a client just
wants to authenticate the server and encrypt all data. The example is in C++,
but the API is similar for all languages: you can see how to enable SSL/TLS in
more languages in our Examples section below.

```cpp
// Create a default SSL ChannelCredentials object.
auto channel_creds = grpc::SslCredentials(grpc::SslCredentialsOptions());
// Create a channel using the credentials created in the previous step.
auto channel = grpc::CreateChannel(server_name, channel_creds);
// Create a stub on the channel.
std::unique_ptr<Greeter::Stub> stub(Greeter::NewStub(channel));
// Make actual RPC calls on the stub.
grpc::Status s = stub->sayHello(&context, *request, response);
```

For advanced use cases such as modifying the root CA or using client certs,
the corresponding options can be set in the `SslCredentialsOptions` parameter
passed to the factory method.

{{% alert title="Note" color="info" %}}
  Non-POSIX-compliant systems (such as Windows) need to specify the root
  certificates in `SslCredentialsOptions`, since the defaults are only
  configured for POSIX filesystems.
{{% /alert %}}

#### Using OAuth token-based authentication

OAuth 2.0 Protocol is the industry-standard protocol for authorization. It enables
websites or applications to obtain limited access to user accounts using OAuth tokens.

gRPC offers a set of simple APIs to integrate OAuth 2.0 into applications, streamlining authentication.

At a high level, using OAuth token-based authentication includes 3 steps:

1. Get or generate an OAuth token on client side.
   * You can generate Google-specific tokens following instructions below.
2. Create credentials with the OAuth token.
   * OAuth token is always part of per-call credentials, you can also attach the per-call credentials
   to some channel credentials.
   * The token will be sent to server, normally as part of HTTP Authorization header.
3. Server side verifies the token.
   * In most implementations, the validation is done using a server side interceptor.

For details of how to use OAuth token in different languages, please refer to our examples below.

#### Using Google token-based authentication

gRPC applications can use a simple API to create a credential that works for
authentication with Google in various deployment scenarios. Again, our example
is in C++ but you can find examples in other languages in our Examples section.

```cpp
auto creds = grpc::GoogleDefaultCredentials();
// Create a channel, stub and make RPC calls (same as in the previous example)
auto channel = grpc::CreateChannel(server_name, creds);
std::unique_ptr<Greeter::Stub> stub(Greeter::NewStub(channel));
grpc::Status s = stub->sayHello(&context, *request, response);
```

This channel credentials object works for applications using Service Accounts as
well as for applications running in [Google Compute Engine
(GCE)](https://cloud.google.com/compute/).  In the former case, the service
account’s private keys are loaded from the file named in the environment
variable `GOOGLE_APPLICATION_CREDENTIALS`. The keys are used to generate bearer
tokens that are attached to each outgoing RPC on the corresponding channel.

For applications running in GCE, a default service account and corresponding
OAuth2 scopes can be configured during VM setup. At run-time, this credential
handles communication with the authentication systems to obtain OAuth2 access
tokens and attaches them to each outgoing RPC on the corresponding channel.


#### Extending gRPC to support other authentication mechanisms

The Credentials plugin API allows developers to plug in their own type of
credentials. This consists of:

- The `MetadataCredentialsPlugin` abstract class, which contains the pure virtual
  `GetMetadata` method that needs to be implemented by a sub-class created by
  the developer.
- The `MetadataCredentialsFromPlugin` function, which creates a `CallCredentials`
  from the `MetadataCredentialsPlugin`.

Here is example of a simple credentials plugin which sets an authentication
ticket in a custom header.

```cpp
class MyCustomAuthenticator : public grpc::MetadataCredentialsPlugin {
 public:
  MyCustomAuthenticator(const grpc::string& ticket) : ticket_(ticket) {}

  grpc::Status GetMetadata(
      grpc::string_ref service_url, grpc::string_ref method_name,
      const grpc::AuthContext& channel_auth_context,
      std::multimap<grpc::string, grpc::string>* metadata) override {
    metadata->insert(std::make_pair("x-custom-auth-ticket", ticket_));
    return grpc::Status::OK;
  }

 private:
  grpc::string ticket_;
};

auto call_creds = grpc::MetadataCredentialsFromPlugin(
    std::unique_ptr<grpc::MetadataCredentialsPlugin>(
        new MyCustomAuthenticator("super-secret-ticket")));
```

A deeper integration can be achieved by plugging in a gRPC credentials
implementation at the core level. gRPC internals also allow switching out
SSL/TLS with other encryption mechanisms.

### Language guides and examples

These authentication mechanisms will be available in all gRPC's supported
languages. The following table links to examples demonstrating authentication
and authorization in various languages.

| Language | Example                                   | Documentation          |
|----------|-------------------------------------------|------------------------|
| C++      | N/A                                       | N/A                    |
| Go       | [Go Example]                              | [Go Documentation]     |
| Java     | [Java Example TLS] ([Java Example ATLS])  | [Java Documentation]   |
| Python   | [Python Example]                          | [Python Documentation] |


[Go Example]: https://github.com/grpc/grpc-go/tree/master/examples/features/encryption
[Go Documentation]: https://github.com/grpc/grpc-go/tree/master/examples/features/encryption#encryption
[Java Example TLS]: https://github.com/grpc/grpc-java/tree/master/examples/example-tls
[Java Example ATLS]: https://github.com/grpc/grpc-java/tree/master/examples/example-alts
[Java Documentation]: https://github.com/grpc/grpc-java/tree/master/examples/example-tls#hello-world-example-with-tls
[Python Example]: https://github.com/grpc/grpc/tree/master/examples/python/auth
[Python Documentation]: https://github.com/grpc/grpc/tree/master/examples/python/auth#authentication-extension-example-in-grpc-python

### Language guides and examples for OAuth token-based authentication

The following table links to examples demonstrating OAuth token-based
authentication and authorization in various languages.

| Language | Example                                   | Documentation                 |
|----------|-------------------------------------------|-------------------------------|
| C++      | N/A                                       | N/A                           |
| Go       | [Go OAuth Example]                        | [Go OAuth Documentation]      |
| Java     | [Java OAuth Example]                      | [Java OAuth Documentation]    |
| Python   | [Python OAuth Example]                    | [Python OAuth Documentation]  |


[Go OAuth Example]: https://github.com/grpc/grpc-go/tree/master/examples/features/authentication#authentication
[Go OAuth Documentation]: https://github.com/grpc/grpc-go/tree/master/examples/features/authentication#oauth2
[Java OAuth Example]: https://github.com/grpc/grpc-java/tree/master/examples/example-oauth#authentication-example
[Java OAuth Documentation]: https://github.com/grpc/grpc-java/tree/master/examples/example-oauth
[Python OAuth Example]: https://github.com/grpc/grpc/blob/master/examples/python/auth/token_based_auth_client.py
[Python OAuth Documentation]: https://github.com/grpc/grpc/tree/master/examples/python/auth#token-based-authentication


### Additional Examples

The following sections demonstrate how authentication and authorization features
described above appear in other languages not listed above.

#### Ruby

##### Base case - no encryption or authentication

```ruby

stub = Helloworld::Greeter::Stub.new('localhost:50051', :this_channel_is_insecure)
...
```

##### With server authentication SSL/TLS

```ruby
creds = GRPC::Core::ChannelCredentials.new(load_certs)  # load_certs typically loads a CA roots file
stub = Helloworld::Greeter::Stub.new('myservice.example.com', creds)
```

##### Authenticate with Google

```ruby
require 'googleauth'  # from http://www.rubydoc.info/gems/googleauth/0.1.0
...
ssl_creds = GRPC::Core::ChannelCredentials.new(load_certs)  # load_certs typically loads a CA roots file
authentication = Google::Auth.get_application_default()
call_creds = GRPC::Core::CallCredentials.new(authentication.updater_proc)
combined_creds = ssl_creds.compose(call_creds)
stub = Helloworld::Greeter::Stub.new('greeter.googleapis.com', combined_creds)
```

#### Node.js

##### Base case - No encryption/authentication

```js
var stub = new helloworld.Greeter('localhost:50051', grpc.credentials.createInsecure());
```

##### With server authentication SSL/TLS

```js
const root_cert = fs.readFileSync('path/to/root-cert');
const ssl_creds = grpc.credentials.createSsl(root_cert);
const stub = new helloworld.Greeter('myservice.example.com', ssl_creds);
```

##### Authenticate with Google

```js
// Authenticating with Google
var GoogleAuth = require('google-auth-library'); // from https://www.npmjs.com/package/google-auth-library
...
var ssl_creds = grpc.credentials.createSsl(root_certs);
(new GoogleAuth()).getApplicationDefault(function(err, auth) {
  var call_creds = grpc.credentials.createFromGoogleCredential(auth);
  var combined_creds = grpc.credentials.combineChannelCredentials(ssl_creds, call_creds);
  var stub = new helloworld.Greeter('greeter.googleapis.com', combined_credentials);
});
```

##### Authenticate with Google using OAuth2 token (legacy approach)

```js
var GoogleAuth = require('google-auth-library'); // from https://www.npmjs.com/package/google-auth-library
...
var ssl_creds = grpc.Credentials.createSsl(root_certs); // load_certs typically loads a CA roots file
var scope = 'https://www.googleapis.com/auth/grpc-testing';
(new GoogleAuth()).getApplicationDefault(function(err, auth) {
  if (auth.createScopeRequired()) {
    auth = auth.createScoped(scope);
  }
  var call_creds = grpc.credentials.createFromGoogleCredential(auth);
  var combined_creds = grpc.credentials.combineChannelCredentials(ssl_creds, call_creds);
  var stub = new helloworld.Greeter('greeter.googleapis.com', combined_credentials);
});
```

##### With server authentication SSL/TLS and a custom header with token

```js
const rootCert = fs.readFileSync('path/to/root-cert');
const channelCreds = grpc.credentials.createSsl(rootCert);
const metaCallback = (_params, callback) => {
    const meta = new grpc.Metadata();
    meta.add('custom-auth-header', 'token');
    callback(null, meta);
}
const callCreds = grpc.credentials.createFromMetadataGenerator(metaCallback);
const combCreds = grpc.credentials.combineChannelCredentials(channelCreds, callCreds);
const stub = new helloworld.Greeter('myservice.example.com', combCreds);
```

#### PHP

##### Base case - No encryption/authorization

```php
$client = new helloworld\GreeterClient('localhost:50051', [
    'credentials' => Grpc\ChannelCredentials::createInsecure(),
]);
```

##### With server authentication SSL/TLS

```php
$client = new helloworld\GreeterClient('myservice.example.com', [
    'credentials' => Grpc\ChannelCredentials::createSsl(file_get_contents('roots.pem')),
]);
```

##### Authenticate with Google

```php
function updateAuthMetadataCallback($context)
{
    $auth_credentials = ApplicationDefaultCredentials::getCredentials();
    return $auth_credentials->updateMetadata($metadata = [], $context->service_url);
}
$channel_credentials = Grpc\ChannelCredentials::createComposite(
    Grpc\ChannelCredentials::createSsl(file_get_contents('roots.pem')),
    Grpc\CallCredentials::createFromPlugin('updateAuthMetadataCallback')
);
$opts = [
  'credentials' => $channel_credentials
];
$client = new helloworld\GreeterClient('greeter.googleapis.com', $opts);
```

##### Authenticate with Google using OAuth2 token (legacy approach)

```php
// the environment variable "GOOGLE_APPLICATION_CREDENTIALS" needs to be set
$scope = "https://www.googleapis.com/auth/grpc-testing";
$auth = Google\Auth\ApplicationDefaultCredentials::getCredentials($scope);
$opts = [
  'credentials' => Grpc\Credentials::createSsl(file_get_contents('roots.pem'));
  'update_metadata' => $auth->getUpdateMetadataFunc(),
];
$client = new helloworld\GreeterClient('greeter.googleapis.com', $opts);
```

#### Dart

##### Base case - no encryption or authentication

```dart
final channel = new ClientChannel('localhost',
      port: 50051,
      options: const ChannelOptions(
          credentials: const ChannelCredentials.insecure()));
final stub = new GreeterClient(channel);
```

##### With server authentication SSL/TLS

```dart
// Load a custom roots file.
final trustedRoot = new File('roots.pem').readAsBytesSync();
final channelCredentials =
    new ChannelCredentials.secure(certificates: trustedRoot);
final channelOptions = new ChannelOptions(credentials: channelCredentials);
final channel = new ClientChannel('myservice.example.com',
    options: channelOptions);
final client = new GreeterClient(channel);
```

##### Authenticate with Google

```dart
// Uses publicly trusted roots by default.
final channel = new ClientChannel('greeter.googleapis.com');
final serviceAccountJson =
     new File('service-account.json').readAsStringSync();
final credentials = new JwtServiceAccountAuthenticator(serviceAccountJson);
final client =
    new GreeterClient(channel, options: credentials.toCallOptions);
```

##### Authenticate a single RPC call

```dart
// Uses publicly trusted roots by default.
final channel = new ClientChannel('greeter.googleapis.com');
final client = new GreeterClient(channel);
...
final serviceAccountJson =
     new File('service-account.json').readAsStringSync();
final credentials = new JwtServiceAccountAuthenticator(serviceAccountJson);
final response =
    await client.sayHello(request, options: credentials.toCallOptions);
```
