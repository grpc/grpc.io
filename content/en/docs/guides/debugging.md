---
title: Debugging
description: >-
  Explains the debugging process of gRPC applications using [grpcdebug]
---

### Overview
[grpcdebug] is a command line tool within the gRPC ecosystem designed to assist developers in debugging and troubleshooting gRPC services. grpcdebug fetches the internal states of the gRPC library from the application via gRPC protocol and provide a human-friendly UX to browse them. Currently, it supports [Channelz]/[Health] Checking/CSDS (aka. [admin services]). In other words, it can fetch statistics about how many RPCs has being sent or failed on a given gRPC channel, it can inspect address resolution results, it can dump the in-effective xDS configuration that directs the routing of RPCs.

### Setup
Install grpcdebug following the instructions provided in the [grpcdebug installation] and add Golang binaries to your PATH: `export PATH=$PATH:$(go env GOPATH)/bin`.

### Usage
```
grpcdebug is an gRPC service admin CLI

Usage:
  grpcdebug <target address> [flags] <command>

Available Commands:
  channelz    Display gRPC states in a human readable way.
  health      Check health status of the target service (default "").
  help        Help about any command
  xds         Fetch xDS related information.

Flags:
      --credential_file string        Sets the path of the credential file; used in [tls] mode
  -h, --help                          help for grpcdebug
      --security string               Defines the type of credentials to use [tls, google-default, insecure] (default "insecure")
      --server_name_override string   Overrides the peer server name if non empty; used in [tls] mode
  -t, --timestamp                     Print timestamp as RFC3339 instead of human readable strings
  -v, --verbose                       Print verbose information for debugging

Use "grpcdebug <target address>  [command] --help" for more information about a command.
```

### Getting Started
Try out examples in [grpcdebug quick start] using a grpc application exposing [admin services]

[grpcdebug]: https://github.com/grpc-ecosystem/grpcdebug
[grpcdebug installation]: https://github.com/grpc-ecosystem/grpcdebug?tab=readme-ov-file#installation
[Health]:https://github.com/grpc/grpc/blob/master/src/proto/grpc/health/v1/health.proto
[Channelz]: https://github.com/grpc/proposal/blob/master/A14-channelz.md
[grpcdebug quick start]: https://github.com/grpc-ecosystem/grpcdebug?tab=readme-ov-file#quick-start
[admin services]: https://github.com/grpc/proposal/blob/master/A38-admin-interface-api.md
