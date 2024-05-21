---
title: ALTS authentication
linkTitle: ALTS
description: >-
  An overview of gRPC authentication in Go using Application Layer Transport
  Security (ALTS).
weight: 75
spelling: cSpell:ignore creds
code:
  client_credentials: |
    ```go
    import (
      "google.golang.org/grpc"
      "google.golang.org/grpc/credentials/alts"
    )

    altsTC := alts.NewClientCreds(alts.DefaultClientOptions())
    conn, err := grpc.NewClient(serverAddr, grpc.WithTransportCredentials(altsTC))
    ```
  server_credentials: |
    ```go
    import (
      "google.golang.org/grpc"
      "google.golang.org/grpc/credentials/alts"
    )

    altsTC := alts.NewServerCreds(alts.DefaultServerOptions())
    server := grpc.NewServer(grpc.Creds(altsTC))
    ```
  server_authorization: |
    ```go
    import (
      "google.golang.org/grpc"
      "google.golang.org/grpc/credentials/alts"
    )

    clientOpts := alts.DefaultClientOptions()
    clientOpts.TargetServiceAccounts = []string{expectedServerSA}
    altsTC := alts.NewClientCreds(clientOpts)
    conn, err := grpc.NewClient(serverAddr, grpc.WithTransportCredentials(altsTC))
    ```
  client_authorization: |
    ```go
    import (
      "google.golang.org/grpc"
      "google.golang.org/grpc/credentials/alts"
    )

    err := alts.ClientAuthorizationCheck(ctx, []string{"foo@iam.gserviceaccount.com"})
    ```
---

{{% docs/auth_alts %}}
