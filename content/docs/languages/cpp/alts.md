---
title: ALTS authentication in C++
short: ALTS
description: >
  An overview of gRPC authentication in C++ using Application Layer Transport
  Security (ALTS).
weight: 75
spelling: cSpell:ignore Authz creds grpcpp
code:
  client_credentials: |
    ```cpp
    #include <grpcpp/grpcpp.h>
    #include <grpcpp/security/credentials.h>

    using grpc::experimental::AltsCredentials;
    using grpc_impl::experimental::AltsCredentialsOptions;

    auto creds = AltsCredentials(AltsCredentialsOptions());
    std::shared_ptr<grpc::Channel> channel = CreateChannel(server_address, creds);
    ```
  server_credentials: |
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
  server_authorization: |
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
  client_authorization: |
    ```cpp
    #include <grpcpp/server_context.h>
    #include <grpcpp/security/alts_util.h>

    grpc::ServerContext* context;
    grpc::Status status = experimental::AltsClientAuthzCheck(
        context->auth_context(), {"foo@iam.gserviceaccount.com"});
    ```
---

{{% docs/auth_alts %}}
