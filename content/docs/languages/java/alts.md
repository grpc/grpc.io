---
title: ALTS authentication in Java
short: ALTS
description: >
  An overview of gRPC authentication in Java using Application Layer Transport
  Security (ALTS).
weight: 75
code:
  client_credentials: |
    ```java
    import io.grpc.alts.AltsChannelBuilder;
    import io.grpc.ManagedChannel;

    ManagedChannel managedChannel =
        AltsChannelBuilder.forTarget(serverAddress).build();
    ```
  server_credentials: |
    ```java
    import io.grpc.alts.AltsServerBuilder;
    import io.grpc.Server;

    Server server = AltsServerBuilder.forPort(<port>)
        .addService(new MyServiceImpl()).build().start();
    ```
  server_authorization: |
    ```java
    import io.grpc.alts.AltsChannelBuilder;
    import io.grpc.ManagedChannel;

    ManagedChannel channel =
        AltsChannelBuilder.forTarget(serverAddress)
            .addTargetServiceAccount("expected_server_service_account1")
            .addTargetServiceAccount("expected_server_service_account2")
            .build();
    ```
  client_authorization: |
    ```java
    import io.grpc.alts.AuthorizationUtil;
    import io.grpc.ServerCall;
    import io.grpc.Status;

    ServerCall<?, ?> call;
    Status status = AuthorizationUtil.clientAuthorizationCheck(
        call, Lists.newArrayList("foo@iam.gserviceaccount.com"));
    ```
---

{{% docs/auth_alts %}}
