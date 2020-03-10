---
title: .NET Core ❤ gRPC
author: Sourabh Shirhatti
author-link: https://twitter.com/sshirhatti
date: 2019-09-23
---

_This is a guest post by [Sourabh Shirhatti](https://twitter.com/sshirhatti), a Program Manager on the .NET team at Microsoft._

The .NET team at Microsoft has been working in close collaboration with the gRPC team since November 2018 on a new fully managed implementation of gRPC for .NET Core.

We're pleased to announce that **grpc-dotnet** is now available with .NET Core 3.0 today!

## How to get it?

**grpc-dotnet** packages have just been released to [NuGet.org](https://www.nuget.org/profiles/grpc-packages) and are already available for use in your projects. These packages also require the latest .NET Core 3.0 shared framework. You can download the .NET Core 3.0 SDK for your dev machine and build servers from the [.NET Core 3.0 download page](https://aka.ms/netcore3download) to acquire the shared framework.

## Getting Started

As gRPC is now a first-class citizen in .NET ecosystem, gRPC templates are included as part of the .NET SDK. To get started, navigate to a console window after installing the SDK and run the following commands.

```sh
dotnet new grpc -o GrpcGreeter
cd GrpcGreeter
dotnet run
```

To create a gRPC client and test with the newly created gRPC Greeter service, you can [follow the rest of this tutorial here](https://docs.microsoft.com/aspnet/core/tutorials/grpc/grpc-start).

## Doesn't gRPC already work with .NET Core?

There are currently two official implementations of gRPC for .NET:

- [**Grpc.Core**](https://github.com/grpc/grpc/tree/master/src/csharp): The original gRPC C# implementation based on the native gRPC Core library.
- [**grpc-dotnet**](https://github.com/grpc/grpc-dotnet): The new implementation written entirely in C# with no native dependencies and based on the newly released .NET Core 3.0.

The implementations coexist side-by-side and each has its own advantages in terms of available features, integrations, supported platforms, maturity level and performance. Both implementations share the same API for invoking and handling RPCs, thus limiting the lock-in and enabling users to choose the implementation that satisfies their needs the best.

## What's new?

Unlike the existing C-Core based implementation ([Grpc.Core](https://github.com/grpc/grpc/tree/master/src/csharp)), the new libraries ([grpc-dotnet](https://github.com/grpc/grpc-dotnet)) make use of the existing networking primitives in the .NET Core Base Class Libraries (BCL). The diagram below highlights the difference between the existing **Grpc.Core** library and the new **grpc-dotnet** libraries.

<p><img src="/img/grpc-dotnet.svg" alt="gRPC .NET Stack" style="max-width: 800px" /></p>

On the server side, the `Grpc.AspNetCore.Server` package integrates into ASP.NET Core, allowing developers to benefit from ecosystem of common cross-cutting concerns of logging, configuration, dependency injection, authentication, authorization etc. which have already been solved by ASP.NET Core. Popular libraries in the ASP.NET ecosystem such as [Entity Framework Core (ORM)](https://github.com/aspnet/EntityFrameworkCore), [Serilog (Logging library)](https://github.com/serilog/serilog), and [Identity Server](https://github.com/IdentityServer/IdentityServer4) among others now work seamlessly with gRPC.

On the client side, the `Grpc.Net.Client` package builds upon the familiar `HttpClient` API that ships as part of .NET Core. As with the server, gRPC clients greatly benefit from the ecosystem of packages that build upon `HttpClient`. It is now possible to use existing packages such as [**Polly**(Resilience and fault-handling library)](https://github.com/App-vNext/Polly) and [HttpClientFactory(manage HTTPClient lifetimes)](https://docs.microsoft.com/aspnet/core/fundamentals/http-requests) with gRPC clients.

The diagram below captures the exhaustive list of all new .NET packages for gRPC and their relationship with the existing packages.

<p><img src="/img/grpc-dotnet-packages.svg" alt="grpc-dotnet packages" style="max-width: 800px" /></p>

In addition to the newly published packages that ship as part of **grpc-dotnet**, we've also made improvements that benefit both stacks. Visual Studio 2019 ships with language grammar support for protobuf files and automatic generation of gRPC server/client code upon saving a protobuf file without requiring full project rebuilds due to design-time builds.

<p><img src="/img/grpc-visualstudio.png" alt="gRPC in Visual Studio 2019" /></p>

## Feedback

We're were excited about improving the gRPC experience for .NET developers. Please give it a try and let us about any feature ideas or bugs you may encounter at the [grpc-dotnet issue tracker](https://github.com/grpc/grpc-dotnet/issues).
