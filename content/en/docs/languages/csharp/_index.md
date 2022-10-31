---
title: C# / .NET
api_path: grpc/LANG/api/Grpc.Core
---

*This page used to contain the documentation for the original C# implementation
of gRPC based on the native gRPC Core library (i.e. `Grpc.Core` nuget package).
The implementation is currently in maintenance mode and its source code has
been [moved][move-details]. We plan to deprecate
the implementation in the future (see [blogpost][]) and we recommend that
all users use the [grpc-dotnet][] implementation instead.*

The following pages cover the C# implementation of gRPC for .NET
([grpc-dotnet][]):

- [Introduction to gRPC on .NET Core](https://docs.microsoft.com/aspnet/core/grpc)
- [Tutorial: Create a gRPC client and server in ASP.NET Core][tutorial]

Several sample applications are available from the [examples][] folder in the
[grpc-dotnet][] repository.

[move-details]: https://github.com/grpc/grpc/blob/master/src/csharp/README.md
[examples]: https://github.com/grpc/grpc-dotnet/tree/master/examples
[grpc-dotnet]: https://github.com/grpc/grpc-dotnet
[tutorial]: https://docs.microsoft.com/aspnet/core/tutorials/grpc/grpc-start
[blogpost]: https://grpc.io/blog/grpc-csharp-future/
