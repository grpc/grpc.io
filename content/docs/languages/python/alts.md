---
title: ALTS authentication in Python
short: ALTS
description: >
  An overview of gRPC authentication in Python using Application Layer Transport
  Security (ALTS).
weight: 75
spelling: cSpell:ignore creds
code:
  client_credentials: |
    ```python
    import grpc

    channel_creds = grpc.alts_channel_credentials()
    channel = grpc.secure_channel(address, channel_creds)
    ```
  server_credentials: |
    ```python
    import grpc

    server = grpc.server(futures.ThreadPoolExecutor())
    server_creds = grpc.alts_server_credentials()
    server.add_secure_port(server_address, server_creds)
    ```
  # server_authorization:
  # client_authorization:
---

{{% docs/auth_alts %}}
