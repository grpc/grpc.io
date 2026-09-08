---
title: Quick start
description: Get started with gRPC in Julia.
weight: 10
---

## Prerequisites

- **Julia** version 1.10 or higher.

## Client

To call a gRPC service from Julia, use `gRPCClient.jl`.

### Installation

Add the package via the Julia REPL:

```julia
using Pkg
Pkg.add("gRPCClient")
```

### Code Generation

gRPCClient.jl integrates with `ProtoBuf.jl` to automatically generate Julia client stubs for calling gRPC. First, ensure your output directory exists:

```bash
mkdir gen
```

Then, generate the bindings:

```julia
using ProtoBuf
using gRPCClient

# Creates Julia bindings for the messages and RPC defined in test.proto
protojl("test.proto", ".", "gen")
```

For more details, see the [gRPCClient.jl documentation](https://juliaio.github.io/gRPCClient.jl/).

## Server

To implement a gRPC server in Julia, use `gRPCServer.jl`.

For more details, see the [gRPCServer.jl documentation](https://juliaio.github.io/gRPCServer.jl/).
