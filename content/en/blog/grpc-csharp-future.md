---
title: The future of gRPC in C# belongs to grpc-dotnet
date: 2021-05-01
spelling: cSpell:ignore dotnetcore nuget Tattermusch
author:
  name: Jan Tattermusch
  link: https://github.com/jtattermusch
---

**Update 2023-10-02: The maintenance period for `Grpc.Core` has been extended again, until at least October 2024. See [announcement][updates2023] for up to date info on `Grpc.Core`.**

**Update 2022-05-03: The maintenance period for `Grpc.Core` has been extended until May 2023. See [announcement][updates2022] for more info on the future of `Grpc.Core`.**

**TL;DR** grpc-dotnet (the
[Grpc.Net.Client](https://www.nuget.org/packages/Grpc.Net.Client/) and
[Grpc.AspNetCore.Server](https://www.nuget.org/packages/Grpc.AspNetCore.Server/)
nuget packages) is now the recommended gRPC implementation for .NET/C#. The
original gRPC C# implementation (the Grpc.Core nuget package) will enter
maintenance mode and won't be getting any new features and will only receive
important bug fixes and security fixes going forward. The ultimate plan is to
phase out Grpc.Core completely at some point in the future. This announcement
describes the reasons why we have decided to do so and lays out the plan in more
detail.

In September 2019 we [announced][ga]
general availability of a new [gRPC C#
implementation](https://github.com/grpc/grpc-dotnet) that is no longer based on
the gRPC C core native library and that's using the HTTP/2 protocol
implementation that was added in .NET Core 3 and ASP.NET Core 3. We refer to
this implementation as "grpc-dotnet".

When we were introducing the grpc-dotnet implementation, we announced that both
gRPC C# implementations (the new pure C# grpc-dotnet implementation and the
original gRPC C# implementation based on C core native library) would co-exist
side by side, letting the users choose which implementation works best for them.
That made a lot of sense since grpc-dotnet was brand new back then and required
a just-released .NET Core framework, while the original gRPC C# implementation
had been stable for a long time, had lots of users and worked on even very old
.NET Framework versions. Things needed some time to settle.

Since then, the new grpc-dotnet implementation has come a long way: it has been
adopted by many users and became very popular, it has been used by a lot of
applications in production environments, and has also added a lot of interesting
new features. In addition, its main prerequisite, the .NET Core 3 framework, has
been around for a while now and its adoption numbers are growing.

At the same time, while the [original gRPC C#
implementation](https://github.com/grpc/grpc/tree/master/src/csharp) (often
referred to as "Grpc.Core", the name of its nuget package) definitely has its
place and it is hugely popular, we are now nearing a point where some of the
design decisions that made perfect sense back in 2016 (when gRPC C# was released
as GA) no longer have the weight they used to. For example, we decided to base
the gRPC C# implementation on a native library because in 2016, there was no
usable C# HTTP/2 library that we could depend on. By depending on the C core
native library instead, we were able to deliver a stable, high performance gRPC
library much faster than if we had to implement everything in C# from scratch.
But from today's perspective, taking a native dependency doesn't make that much
sense anymore since HTTP/2 support is now built into the .NET Core framework.
The benefits of having a native dependency are diminishing, while the
maintenance burden of having one is staying the same.

Out of the two stable C# implementations, the grpc-dotnet implementation is
definitely the one that has more future potential. It is a more modern
implementation that is well-integrated with the modern versions of .NET and it's
likely going to be more aligned with where the C# community will be a few years
from now. It is also a pure C# implementation (no native components), which
makes it much more contribution friendly, leads to better debuggability and it
is simply also something that C# enthusiasts like to see.

Because the maintenance costs of having two official implementations of gRPC for
C# are nontrivial and because grpc-dotnet seems to be the best choice for all
users in the long run, we would like to **announce the intent to phase out the
original gRPC C# implementation (nuget package Grpc.Core) in favor of the more
modern and more forward-looking grpc-dotnet implementation**.

The details of the plan are described in the following sections, along with
further explanation why it makes sense. To help understand the consequences of
the decision to phase out Grpc.Core, we have also come up with a list of
frequently asked questions and provided answers to them.

### What makes grpc-dotnet the preferred implementation

Simply said, grpc-dotnet seems to be a better bet for the future. Some of the
most important points were already mentioned. Here is a more detailed list of
reasons why we believe grpc-dotnet will serve the users' needs better:

- It's a more modern implementation, based on features of the recent version of
  the .NET framework. As such, it will probably be the more viable one of the
  two implementations in the future.
- It's more aligned with where the C# / .NET community is now and in the future.
  Staying aligned with where the community is heading seems to be the best bet
  for the future of gRPC in C#.
- The implementation is much more agile and contribution friendly - because it's
  internally based on well known primitives / APIs (ASP.NET core serving APIs
  and HTTP2 client) and it's implemented in pure C#, the code is much more
  accessible to C# developers (both to users that just want to understand how
  things work and to potential contributors who would author PRs). The
  grpc-dotnet codebase is relatively small, it takes seconds to build, running
  the tests is easy and quick. In the long run, easier development and
  contribution friendliness should make up for some of the features that are
  missing today and make it a superior choice for the users -- that is,
  lowering the barrier to
  contribute and fix/improve stuff translates into more stuff being fixed and
  better user experience after some time.
- Having a library that is implemented in pure C# is something that's generally
  favored by the .NET community, compared to an implementation that depends on a
  native component. While C# has good support for interoperating with native
  libraries, it is a technique that most C# developers are not familiar with and
  it looks like a black box to them. Native interop is tricky to get it right
  and has many downsides (e.g. more complicated development and build process,
  complex debugging, hard to maintain, hard to get community contributions, hard
  to provide support for multiple platforms). With Grpc.Core we were able to
  overcome most of these challenges (so things work these days), but it has been
  a lot of effort, the solutions are sometimes complex and fragile and
  maintaining it is costly and requires a lot of expertise.

  NOTE: the Google.Protobuf library for C# is already written purely in C# (no
  native components), so having a pure C# implementation of gRPC gets rid of
  native components from developers' microservice stack completely

### Why not keep Grpc.Core forever?

Developing two implementations of gRPC in C# isn't free. It costs valuable
resources and we believe that the engineering time would be better spent on
making gRPC in C# easier to use and on adding new features (and fixing bugs of
course), rather than needing to work on two different codebases that both serve
the same purpose.  Also, having two separate implementations necessarily
fragments the user base to some extent and splits the contributors' efforts into
two. Also just the simple act of users needing to choose which of the two
implementations they want to bet on comes with uncertainty and inherent risk
(none of which we want for our users).

By making grpc-dotnet the recommended implementation and by making the Grpc.Core
implementation "maintenance only" (and eventually phasing it out), we are aiming
to achieve the following goals:

- Free up engineering resources to work on better features and better usability.
- Unify the gRPC C# user base. This will lead to directing all community work
  and contributions toward a single implementation. It also removes the inherent
  friction caused by the user needing to choose which of the two official
  implementations to use.
- Address some of the well known pain points of Grpc.Core that would be too
  difficult to address by other means.
- Futureproof C#/.NET implementation of gRPC by staying aligned with the .NET
  community.


### The plan

**Phase 1: Grpc.Core becomes "Maintenance Only"**

**When: Effective immediately (May 2021)**

From now on, we are no longer going to provide new features or enhancements for
Grpc.Core. Important bugs and security issues will continue to be addressed in a
normal way.

We will publish Grpc.Core releases normally, with the usual 6 weekly cadence.

The releases will be based on the newest grpc C core native library build, so
all new features that don't require C# specific work will also be included.

**Phase 2: Grpc.Core becomes "Deprecated"**

**When: 1 year from now (May 2022)**

Once this milestone is reached, Grpc.Core will no longer be officially supported
and all the users will be strongly advised to only use grpc-dotnet from this
point onwards.

The Grpc.Core nuget packages will remain available in the nuget.org repository,
but no more fixes will be provided (= not even security fixes).

**Future of Grpc.Tools and Grpc.Core.Api nuget packages**

Both packages will continue to be fully supported, since they are strictly
speaking not part of Grpc.Core and they are also used by grpc-dotnet.

- the Grpc.Tools nuget package which provides the codegen build integration for
  C# projects will continue to be supported (and will potentially get
  improvements) -- as it's used by both Grpc.Core and grpc-dotnet. This package
  is independent of C core.
- Grpc.Core.Api package is a prerequisite for grpc-dotnet so it will potentially
  evolve over time as well (but it's a pure C# API only package and since it
  only contains the public API surface, changes are very infrequent)


### Q & A

**I'm a current Grpc.Core user, what does this mean for me?**

While we are going to continue supporting Grpc.Core for a while (see the
deprecation schedule for details), you'll have to migrate your project to
grpc-dotnet if you wish to continue getting updates and bug fixes in the future.

**How do I migrate my existing project to grpc-dotnet?**

Since Grpc.Core and grpc-dotnet are two distinct libraries, there are going to
be some code changes necessary in your project. Since both implementations share
the same API for invoking and handling RPCs (we've intentionally designed them
to be that way), we believe that the code changes necessary should be fairly
minimal. For many applications you'll simply need to change the way you
configure your gRPC channels and servers; that is usually only a small portion
of your app's implementation and tends to be separate from the business logic.

For more tips on how to migrate from Grpc.Core to grpc-dotnet, see [Migrating
gRPC services from C-core to ASP.NET
Core](https://docs.microsoft.com/en-us/aspnet/core/grpc/migration).

We plan to publish a more detailed migration guide in the future to facilitate
the migration from Grpc.Core to grpc-dotnet.

**I'd like to use gRPC in C# for a new project. Which implementation should I choose?**

We strongly recommend only using grpc-dotnet for new projects. We are going to
stop supporting Grpc.Core in the future.

**Does this mean I need to stop using Grpc.Core right now?**

No, Grpc.Core will continue to be supported for a while (see the deprecation
schedule). There should be enough time for you to assess the situation and plan
your migration.

**I'm not using gRPC directly in my code, but I'm using the Google Cloud Client Libraries (which do use Grpc.Core under the hood). How does this impact me?**

This deprecation does not currently impact existing users of Google Cloud Client
Libraries.

Since Grpc.Core is an integral part of these client libraries, security and bug
fixes for Grpc.Core will continue to be provided for Google Cloud Client
Libraries.

The client libraries for which the extended support will be provided:

- [Google Cloud Libraries for .NET](https://github.com/googleapis/google-cloud-dotnet)
- [Google Ads Client Library for .NET](https://github.com/googleads/google-ads-dotnet/)

Note that the extended support of Grpc.Core will only be provided for Grpc.Core
when used as part of these client libraries. For other use cases than the Google
Cloud Client Libraries, Grpc.Core won't be officially supported past the
deprecation date and users must migrate existing workloads to grpc-dotnet before
the deprecation happens.

**Where can I find the list of supported features?**

Our [documentation on
github](https://github.com/grpc/grpc-dotnet/blob/master/doc/implementation_comparison.md)
has a comparison of supported features.

**I have an important Grpc.Core use case that is not covered by this document.**

We welcome your feedback! Write to us through the [grpc-io][] Google Group, or
any other of the main [gRPC community channels]({{<relref community >}}).

[ga]: {{< relref grpc-on-dotnetcore >}}
[grpc-io]: https://groups.google.com/g/grpc-io
[updates2022]: https://groups.google.com/g/grpc-io/c/OTj5mb1qzb0
[updates2023]: https://groups.google.com/g/grpc-io/c/iEalUhV4VrU
