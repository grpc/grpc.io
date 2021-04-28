---
spelling: cSpell:ignore dotnetcore nuget Tattermusch
draft: true
title: The future of gRPC in C# belongs to grpc-dotnet
date: 2021-04-29
author:
  name: Jan Tattermusch
  link: https://github.com/jtattermusch
---

We, the gRPC team, are announcing today a **[phase-out plan][] for the original
gRPC C# implementation** ([Grpc.Core][]). This post explains why we're doing so,
provides phase-out plan details, and attempts to answer (anticipated) frequently
asked questions.

## Evolution of gRPC support for C#

We first introduced C# support for gRPC back in 2016, with a [gRPC-Core based
implementation][grpc-core-csharp], most often referred to as **[Grpc.Core][]**,
the name of its nuget package.

In September 2019, we [announced the general availability][ga] of
**[grpc-dotnet][]**, a new **pure-C#** implementation of gRPC for .NET Core.

{{% alert title="Note" color="info" %}}
  For a detailed comparison of these two implementations, see [grpc-dotnet and
  Grpc.Core comparison][comparison].

  [comparison]: https://github.com/grpc/grpc-dotnet/blob/master/doc/implementation_comparison.md
{{% /alert %}}

Since then, grpc-dotnet has continued to mature and significantly increase
both its feature set and user-base.

We've reached a point where we can no longer justify the maintenance costs of
two implementations of gRPC for C#. The Grpc.Core implementation is based on
design tradeoffs that made sense in 2016, but are no longer optimal -- this
makes it a good candidate for a progressive retirement.

In contrast, the modern design of grpc-dotnet is the best choice for the
community that it serves, given its seamless integration with .Net: as a pure C#
implementation, it will be easier to use and debug. This also makes it more
contribution-friendly for C# community members.

## Phase-out plan {#plan}

### Phase 1: maintenance-only

**When: Effective immediately (May 2021)**

Effective immediately, Grpc.Core is in maintenance-only mode: we won't provide
Grpc.Core with new features or enhancements. Important bugs and security issues
will continue to be addressed in a normal way.

We will publish Grpc.Core releases normally, with the usual 6 weekly cadence.

The releases will be based on the newest grpc C core native library build, so
all new features that don't require C# specific work will also be included.

### Phase 2: deprecation

**When: 1 year from now (May 2022)**

Grpc.Core is deprecated: once this milestone is reached, Grpc.Core will no
longer be officially supported. All the users will be strongly advised to
transition to grpc-dotnet.

The Grpc.Core nuget packages will remain available in the [nuget.org][]
repository, but no more fixes will be provided -- not even security fixes.

## Questions and answers

### I'm using Grpc.Core, what does this mean for me?

While we are going to continue supporting Grpc.Core for a while (see the
deprecation schedule for details), you'll have to migrate your project to
grpc-dotnet if you wish to continue getting updates and bug fixes in the future.

### How do I migrate my existing project to grpc-dotnet?

Since Grpc.Core and grpc-dotnet are two distinct libraries, there are going to
be some code changes necessary in your project. Since both implementations share
the same API for invoking and handling RPCs (we've intentionally designed them
to be that way), we believe that the code changes necessary should be fairly
minimal. For many applications you'll simply need to change the way you
configure your gRPC channels and servers; that is usually only a small portion
of your app's implementation and tends to be separate from the business logic.

See [Migrating gRPC services from C-core to ASP.NET
Core](https://docs.microsoft.com/en-us/aspnet/core/grpc/migration) for more tips
on how to migrate from Grpc.Core to grpc-dotnet.

We plan to publish a more detailed migration guide in the future to facilitate
the migration from Grpc.Core to grpc-dotnet.

### I'd like to use gRPC in C# for a new project. Which implementation should I choose?

We strongly recommend only using grpc-dotnet for new projects. We are going to
stop supporting Grpc.Core in the future.

### Does this mean I need to stop using Grpc.Core right now?

No, Grpc.Core will continue to be supported for a while (see the deprecation
schedule). There should be enough time for you to assess the situation and plan
your migration.

### I'm using Google Cloud Client Libraries, does this impact me?

Google Cloud Client Libraries use Grpc.Core under the hood. The Grpc.Core
phase-out plan does not impact existing users of these libraries at the moment.

Since Grpc.Core is an integral part of these client libraries, security and bug
fixes for Grpc.Core will continue to be provided for Google Cloud Client
Libraries.

The client libraries for which we will provide extended support are the
following:

- [Google Cloud Libraries for .NET](https://github.com/googleapis/google-cloud-dotnet)
- [Google Ads Client Library for .NET](https://github.com/googleads/google-ads-dotnet/)

Note that the extended support of Grpc.Core will only be provided for Grpc.Core
when used as part of these client libraries. For other use cases than the Google
Cloud Client Libraries, Grpc.Core won't be officially supported past the
deprecation date and users must migrate existing workloads to grpc-dotnet before
the deprecation happens.

### What will happen to Grpc.Tools and Grpc.Core.Api?

Both the Grpc.Tools and Grpc.Core.Api packages will continue to be fully
supported, since they are -- strictly speaking -- not part of Grpc.Core and they
are also used by grpc-dotnet.

### I have an important Grpc.Core use case that is not covered by this document

We welcome your feedback! Write to us through the [grpc-io][] Google Group, or any other of the main [gRPC community channels][].

[comparison]: https://github.com/grpc/grpc-dotnet/blob/master/doc/implementation_comparison.md
[ga]: {{< relref grpc-on-dotnetcore >}}
[gRPC community channels]: {{<relref community >}}
[grpc-core-csharp]: https://github.com/grpc/grpc/tree/v1.37.0/src/csharp
[grpc-dotnet]: https://github.com/grpc/grpc-dotnet
[grpc-io]: https://groups.google.com/forum/#!forum/grpc-io
[Grpc.Core]: https://www.nuget.org/packages/Grpc.Core/
[nuget.org]: https://www.nuget.org/
[phase-out plan]: #plan
