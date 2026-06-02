---
title: gRPC-Rust Roadmap
date: 2026-06-02
spelling: cSpell:ignore
author:
  name: Doug Fawley
  position: Google
---

With the [release of our client-side preview](../grpc-rust-announcement) done,
I'd like to spend some time talking about what you can expect to see next from
the gRPC-Rust team.

## In progress

The biggest and most important thing under active development is the server API.
This will be a natural extension of the client API, sharing types where
possible.  Expect to see another preview announcement when it's ready!

In addition, we're already hard at work on several more client-side features
like integrated [health
checking](https://github.com/grpc/proposal/blob/master/A17-client-side-health-checking.md)
and [message
compression](https://github.com/grpc/grpc/blob/master/doc/compression.md).

Finally, we're working to bulk up our testing and implement the full [gRPC
Interop test
suite](https://github.com/grpc/grpc/blob/master/doc/interop-test-descriptions.md)
so that gRPC-Rust can be declared production-worthy.

## Next up

Looking even further ahead, there are many other features and changes that are
planned:

* Significant gRPC features:
  [Retries](https://github.com/grpc/proposal/blob/master/A6-client-retries.md),
  [Binary
  Logging](https://github.com/grpc/proposal/blob/master/A16-binary-logging.md),
  [Channelz
  Debugging](https://github.com/grpc/proposal/blob/master/A14-channelz.md),
  [Keepalive
  support](https://github.com/grpc/proposal/blob/master/A8-client-side-keepalive.md),
  [Authz](https://github.com/grpc/proposal/blob/master/A43-grpc-authorization-api.md),
  etc.  These features will be released as they become available.

* Full xDS ([Envoy](https://www.envoyproxy.io/)) support is a longer-term goal
  the team will be heavily focused on for the next several months.  In addition
  to [Proxyless Service
  Mesh](https://docs.cloud.google.com/service-mesh/legacy/load-balancing-apis/proxyless-configure-advanced-traffic-management)
  (PSM) use cases, this feature enables [direct
  connectivity](https://docs.cloud.google.com/storage/docs/direct-connectivity)
  for Google Cloud services.

* gRPC Status -> Abseil Status: the [gRPC status type in
  C++](https://grpc.github.io/grpc/cpp/classgrpc_1_1_status.html) is very
  similar to [`absl::Status`](https://abseil.io/docs/cpp/guides/status), and not
  by accident -- but their minor *internal* differences have caused some pain.
  Instead of using our own status type, we intend to standardize on a shared
  Rust RPC status type.  We're eagerly awaiting the stabilization of the [Try
  trait](https://github.com/rust-lang/rust-project-goals/blob/main/src/2026/stabilize-try.md),
  which will allow this new type to ergonomically provide some very useful
  features.  More details on that change will be released when they are
  available.

* Performance tuning: while we are initially focusing on "getting things done",
  we will also be looking at how we can improve performance over what the
  preview offers.  We'll be looking at reducing memory usage (overall and per
  connection), zero-copy support, and a lower-level HTTP/2 implementation,
  resulting in higher throughput, lower latency, and more parallelism.

## Join us at gRPConf 2026!

If you're interested in meeting the gRPC team, discussing related topics with
others in the industry, or maybe even sharing your own experiences or advice in
a talk, please mark your calendar for **Thursday, September 3rd**, when we'll be
holding this year's gRPC developer's conference at the [Computer History
Museum](https://computerhistory.org/) in Mountain View, CA.

* **Event Site:** [gRPConf](https://events.linuxfoundation.org/grpconf/)
* **CFP is open:** [Submit your talk!](https://events.linuxfoundation.org/grpconf/program/cfp/)
