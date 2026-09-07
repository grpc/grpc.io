---
title: Basics tutorial
description: A basic tutorial introduction to gRPC in Julia.
weight: 50
---

This guide provides a basic introduction to working with gRPC in Julia.

By walking through this example you'll learn how to:

- Define a service in a `.proto` file.
- Generate client and server code using the protocol buffer compiler.
- Use the Julia gRPC API to write a simple client and server for your service.

It assumes that you have read the [Introduction to gRPC](/docs/what-is-grpc/introduction/) and are familiar with [protocol buffers](https://protobuf.dev/overview).

## Example Code and Setup

Julia's gRPC support is split between two primary packages:

- [gRPCClient.jl](https://github.com/JuliaIO/gRPCClient.jl) for writing gRPC clients.
- [gRPCServer.jl](https://github.com/JuliaIO/gRPCServer.jl) for writing gRPC servers.

To follow detailed examples for building clients and servers, please refer directly to the documentation for these packages:
- [gRPCClient.jl Documentation](https://juliaio.github.io/gRPCClient.jl)
- [gRPCServer.jl Examples](https://github.com/JuliaIO/gRPCServer.jl)

### Code Generation

To generate Julia code from your `.proto` files, you'll use `ProtoBuf.jl` along with the generators provided by the respective client or server packages.

For example, to generate a client stub, first ensure the output directory exists (`mkdir gen`), and then run:

```julia
using ProtoBuf
using gRPCClient

protojl("route_guide.proto", ".", "gen")
```

This generates Julia structs and methods corresponding to your Protocol Buffers definitions.
