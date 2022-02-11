---
title: Credential Reloading on File Changes
description: >-
  An overview of how to enable an experimental feature, credential reloading on 
  file changes, in gRPC C++, Java and Go.
---

### Overview

`AdvancedTLS` is a set of security features we wanted to introduce to our 
open-source users who want more advanced controls over their TLS connections. 
Credential reloading is one important feature in AdvancedTLS.

When we refer to the credential, we usually mean the following three pieces:
1. private key, which should be kept in a safe place,
2. identity certificate chain, which is sent to the peers to prove endpoint's 
identity, and
3. trust certificate bundle, which basically tells which CA to trust

In normal mutual TLS connections, once the credential set is configured, there 
is no easy way to change it without shutting down the server, or re-creating the 
client. This will create some problems if we want a long-lived server, or we 
want to start a long-lived connection from the client, because the certificates 
can expire and certificate rotations are required.

To solve this problem, we introduced a new set of APIs to reload credentials 
from disk. To use it, users just need to specify the file paths for the 
credentials when creating their client/server. gRPC will monitor the changes of 
those files, and update them when necessary. When there is a need to use new 
credentials, simply change the file contents on disk, while the gRPC 
server/client is running. When gRPC notices the files are changed, it will 
reload the credentials and use them on future connections.

This feature is already supported in C++, Java and Go, in an API consistent way. 
This document talks about how to enable these features in each language.

Please note that **the APIs are experimental so the usages in this document are 
subject to be changed**. While we welcome more users to try and use the new API, 
it should also be kept in mind that we don't guarantee the backward 
compatibility of these APIs.


### C++

Credential reloading is configured through TLS options. It can be used on both 
client and server side.

On the client side,

``` cpp
grpc::experimental::TlsChannelCredentialsOptions options;

// set up credential reloading in options
auto certificate_provider = std::make_shared<FileWatcherCertificateProvider>(
      CLIENT_KEY_PATH, CLIENT_CERT_PATH, CA_CERT_PATH, /*refresh_interval_sec=*/1);
grpc::experimental::TlsChannelCredentialsOptions options;
options.set_certificate_provider(certificate_provider);
// Tells gRPC to watch the updates of the credentials
options.watch_root_certs();
options.watch_identity_key_cert_pairs();
// kRootCertName and kIdentityCertName don't matter in this case - it can be any string that you wish to have as a alias for the cert name, or just use an empty string
options.set_root_cert_name(kRootCertName);
options.set_identity_cert_name(kIdentityCertName);
auto channel_credentials = grpc::experimental::TlsCredentials(options);

// Use options to create the credential
auto channel_creds = grpc::experimental::TlsCredentials(options);
auto channel = grpc::CreateChannel("myservice.example.com", channel_creds);
std::unique_ptr<Greeter::Stub> stub(Greeter::NewStub(channel));
// ...
```
On the server side,

``` cpp
// provider is mandatory for the server - see next section for details
auto certificate_provider = std::make_shared<FileWatcherCertificateProvider>(...);
grpc::experimental::TlsServerCredentialsOptions options(certificate_provider);

// set up credential reloading in options
auto certificate_provider = std::make_shared<FileWatcherCertificateProvider>(
      SERVER_KEY_PATH, SERVER_CERT_PATH, CA_CERT_PATH, /*refresh_interval_sec=*/1);
grpc::experimental::TlsChannelCredentialsOptions options;
options.set_certificate_provider(certificate_provider);
// Tells gRPC to watch the updates of the credentials
options.watch_root_certs();
options.watch_identity_key_cert_pairs();
// kRootCertName and kIdentityCertName don't matter in this case - it can be any string that you wish to have as a alias for the cert name, or just use an empty string
options.set_root_cert_name(kRootCertName);
options.set_identity_cert_name(kIdentityCertName);
auto channel_credentials = grpc::experimental::TlsCredentials(options);

// Use options to create the credential
auto server_credentials = grpc::experimental::TlsServerCredentials(options);
GreeterServiceImpl service;
ServerBuilder builder;
builder.AddListeningPort("0.0.0.0:50051", server_credentials);
builder.RegisterService(&service);
std::unique_ptr<Server> server(builder.BuildAndStart());
// ...
```

### Java

On the client side,

``` java
AdvancedTlsX509KeyManager clientKeyManager = new AdvancedTlsX509KeyManager();
Closeable clientKeyShutdownclientKeyManager.updateIdentityCredentialsFromFile(
        CLIENT_KEY_PATH,
        CLIENT_CERT_PATH,100, TimeUnit.MILLISECONDS, executor);
AdvancedTlsX509TrustManager clientTrustManager = AdvancedTlsX509TrustManager
        .newBuilder()
        .setVerification(Verification.CERTIFICATE_AND_HOST_NAME_VERIFICATION)
        .build();
Closeable clientTrustShutdown = clientTrustManager
        .updateTrustCredentialsFromFile(CA_CERT_PATH,
        100, TimeUnit.MILLISECONDS, executor);
ChannelCredentials channelCredentials = TlsChannelCredentials.newBuilder()
        .keyManager(clientKeyManager).trustManager(clientTrustManager).build();
ManagedChannel channel = Grpc.newChannelBuilderForAddress("localhost", 50051,   
        channelCredentials).build();
GreeterGrpc.GreeterStub stub = GreeterGrpc.newStub(channel);
// ...
// Clean up.
clientKeyShutdown.close();
clientTrustShutdown.close();
```
On the server side,

``` java
AdvancedTlsX509KeyManager serverKeyManager = new AdvancedTlsX509KeyManager();
Closeable serverKeyShutdown = serverKeyManager.updateIdentityCredentialsFromFile(
        SERVER_KEY_PATH, SERVER_CERT_PATH, 100, TimeUnit.MILLISECONDS, executor);
AdvancedTlsX509TrustManager serverTrustManager = AdvancedTlsX509TrustManager
        .newBuilder()
        .setVerification(Verification.CERTIFICATE_ONLY_VERIFICATION)
        .build();
Closeable serverTrustShutdown = serverTrustManager.updateTrustCredentialsFromFile(
        CA_CERT_PATH,
        100, TimeUnit.MILLISECONDS, executor);
ServerCredentials serverCredentials = TlsServerCredentials.newBuilder()
        .keyManager(serverKeyManager).trustManager(serverTrustManager)
        .clientAuth(ClientAuth.REQUIRE).build();
Server server = Grpc.newServerBuilderForPort(0, serverCredentials)
        .addService(new SimpleServiceImpl()).build()
        .start();
// ...
// Clean up.
serverKeyShutdown.close();
serverTrustShutdown.close();
```

### Go

On the client side,

``` go
import "google.golang.org/grpc/security/advancedtls"

identityOptions := pemfile.Options{
    CertFile:        CLIENT_CERT_PATH,
    KeyFile:         CLIENT_KEY_PATH,
    RefreshDuration: 500 * time.Millisecond,
}
identityProvider, err := pemfile.NewProvider(identityOptions)
// Confirm err is nil
defer identityProvider.Close()
rootOptions := pemfile.Options{
    RootFile:        CA_CERT_PATH,
    RefreshDuration: 500 * time.Millisecond,
}
rootProvider, err := pemfile.NewProvider(rootOptions)
// Confirm err is nil
defer rootProvider.Close()
options := &advancedtls.ClientOptions{
        IdentityOptions: advancedtls.IdentityCertificateOptions{
                IdentityProvider: identityProvider,
        },
        RootOptions: advancedtls.RootCertificateOptions{
                RootProvider: rootProvider,
        },
}
clientTLSCreds, err := advancedtls.NewClientCreds(options)

// Make a connection using the credentials.
conn, _ := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(clientCreds))
client := pb.NewGreeterClient(conn)
// ....
```
On the server side,

``` go
import "google.golang.org/grpc/security/advancedtls"

identityOptions := pemfile.Options{
    CertFile:        SERVER_CERT_PATH,
    KeyFile:         SERVER_KEY_PATH,
    RefreshDuration: 500 * time.Millisecond,
}
identityProvider, err := pemfile.NewProvider(identityOptions)
// Confirm err is nil
defer identityProvider.Close()
rootOptions := pemfile.Options{
    RootFile:        CA_CERT_PATH,
    RefreshDuration: 500 * time.Millisecond,
}
rootProvider, err := pemfile.NewProvider(rootOptions)
// Confirm err is nil
defer rootProvider.Close()
options := &advancedtls.ClientOptions{
        IdentityOptions: advancedtls.IdentityCertificateOptions{
                IdentityProvider: identityProvider,
        },
        RootOptions: advancedtls.RootCertificateOptions{
                RootProvider: rootProvider,
        },
}
serverTLSCreds, err := advancedtls.NewServerCreds(options)

s := grpc.NewServer(grpc.Creds(serverTLSCreds), grpc.KeepaliveParams(keepalive.ServerParameters{
        // Set the max connection time to be 0.5s to force the client to re-establish 
        // the connection, and hence re-invoke the verification callback.
        MaxConnectionAge: 500 * time.Millisecond,
}))
lis, err := net.Listen("tcp", port)
// Confirm err is nil
pb.RegisterGreeterServer(s, greeterServer{})
if err := s.Serve(lis); err != nil {
        log.Fatalf("failed to serve: %v", err)
}
// ....
```