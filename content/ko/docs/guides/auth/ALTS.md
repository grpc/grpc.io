---
title: ALTS 인증
description: >
  An overview of gRPC authentication using Application Layer Transport Security
  (ALTS).
---

### Overview

Application Layer Transport Security (ALTS) is a mutual authentication and
transport encryption system developed by Google. It is used for securing RPC
communications within Google's infrastructure. ALTS is similar to mutual TLS
but has been designed and optimized to meet the needs of Google's production
environments. For more information, take a look at the
[ALTS whitepaper](https://cloud.google.com/security/encryption-in-transit/application-layer-transport-security).

ALTS in gRPC has the following features:

-   Create gRPC servers & clients with ALTS as the transport security protocol.
-   ALTS connections are end-to-end protected with privacy and integrity.
-   Applications can access peer information such as the peer service account.
-   Client authorization and server authorization support.
-   Minimal code changes to enable ALTS.

gRPC users can configure their applications to use ALTS as a transport security
protocol with few lines of code. gRPC ALTS is supported in C++, Java, Go, and
Python.

Note that ALTS is fully functional if the application runs on
[Google Cloud Platform](https://cloud.google.com/). ALTS could be run on any
platforms with a pluggable
[ALTS handshaker service](https://github.com/grpc/grpc/blob/7e367da22a137e2e7caeae8342c239a91434ba50/src/proto/grpc/gcp/handshaker.proto#L224-L234).

### gRPC Client with ALTS Transport Security Protocol

gRPC clients can use ALTS credentials to connect to servers. The following
provides examples of how to set up such clients in all supported gRPC languages.

#### C++

```cpp
#include <grpcpp/grpcpp.h>
#include <grpcpp/security/credentials.h>

using grpc::experimental::AltsCredentials;
using grpc_impl::experimental::AltsCredentialsOptions;

auto creds = AltsCredentials(AltsCredentialsOptions());
std::shared_ptr<grpc::Channel> channel = CreateChannel(server_address, creds);
```

#### Java

```java
import io.grpc.alts.AltsChannelBuilder;
import io.grpc.ManagedChannel;

ManagedChannel managedChannel =
    AltsChannelBuilder.forTarget(serverAddress).build();
```

#### Go

```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)

altsTC := alts.NewClientCreds(alts.DefaultClientOptions())
conn, err := grpc.Dial(serverAddr, grpc.WithTransportCredentials(altsTC))
```

#### Python

```python
import grpc

channel_creds = grpc.alts_channel_credentials()
channel = grpc.secure_channel(address, channel_creds)
```

### gRPC Server with ALTS Transport Security Protocol

gRPC servers can use ALTS credentials to allow clients to connect to them. The
following provides examples of how to set up such servers in all supported gRPC
languages.

#### C++

```cpp
#include <grpcpp/security/server_credentials.h>
#include <grpcpp/server.h>
#include <grpcpp/server_builder.h>

using grpc::experimental::AltsServerCredentials;
using grpc_impl::experimental::AltsServerCredentialsOptions;

grpc::ServerBuilder builder;
builder.RegisterService(&service);
auto creds = AltsServerCredentials(AltsServerCredentialsOptions());
builder.AddListeningPort("[::]:<port>", creds);
std::unique_ptr<Server> server(builder.BuildAndStart());
```

#### Java

```java
import io.grpc.alts.AltsServerBuilder;
import io.grpc.Server;

Server server = AltsServerBuilder.forPort(<port>)
    .addService(new MyServiceImpl()).build().start();

```

#### Go

```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)

altsTC := alts.NewServerCreds(alts.DefaultServerOptions())
server := grpc.NewServer(grpc.Creds(altsTC))
```

#### Python

```python
import grpc

server = grpc.server(futures.ThreadPoolExecutor())
server_creds = grpc.alts_server_credentials()
server.add_secure_port(server_address, server_creds)
```

### Server Authorization

gRPC has built-in server authorization support using ALTS. A gRPC client using
ALTS can set the expected server service accounts prior to establishing a
connection. Then, at the end of the handshake, server authorization guarantees
that the server identity matches one of the service accounts specified
by the client. Otherwise, the connection fails.

#### C++

```cpp
#include <grpcpp/grpcpp.h>
#include <grpcpp/security/credentials.h>

using grpc::experimental::AltsCredentials;
using grpc_impl::experimental::AltsCredentialsOptions;

AltsCredentialsOptions opts;
opts.target_service_accounts.push_back("expected_server_service_account1");
opts.target_service_accounts.push_back("expected_server_service_account2");
auto creds = AltsCredentials(opts);
std::shared_ptr<grpc::Channel> channel = CreateChannel(server_address, creds);
```

#### Java

```java
import io.grpc.alts.AltsChannelBuilder;
import io.grpc.ManagedChannel;

ManagedChannel channel =
     AltsChannelBuilder.forTarget(serverAddress)
         .addTargetServiceAccount("expected_server_service_account1")
         .addTargetServiceAccount("expected_server_service_account2")
         .build();
```

#### Go

```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)

clientOpts := alts.DefaultClientOptions()
clientOpts.TargetServiceAccounts = []string{expectedServerSA}
altsTC := alts.NewClientCreds(clientOpts)
conn, err := grpc.Dial(serverAddr, grpc.WithTransportCredentials(altsTC))
```

### Client Authorization

On a successful connection, the peer information (e.g., client’s service
account) is stored in the
[AltsContext](https://github.com/grpc/grpc/blob/master/src/proto/grpc/gcp/altscontext.proto).
gRPC provides a utility library for
client authorization check. Assuming that the server knows the expected client
identity (e.g., foo@iam.gserviceaccount.com), it can run the following example
codes to authorize the incoming RPC.

#### C++

```cpp
#include <grpcpp/server_context.h>
#include <grpcpp/security/alts_util.h>

grpc::ServerContext* context;
grpc::Status status = experimental::AltsClientAuthzCheck(
    context->auth_context(), {"foo@iam.gserviceaccount.com"});
```

#### Java

```java
import io.grpc.alts.AuthorizationUtil;
import io.grpc.ServerCall;
import io.grpc.Status;

ServerCall<?, ?> call;
Status status = AuthorizationUtil.clientAuthorizationCheck(
    call, Lists.newArrayList("foo@iam.gserviceaccount.com"));
```

#### Go

```go
import (
  "google.golang.org/grpc"
  "google.golang.org/grpc/credentials/alts"
)

err := alts.ClientAuthorizationCheck(ctx, []string{"foo@iam.gserviceaccount.com"})
```
