---
title: gRPC-Rust Preview Release
date: 2026-05-18
spelling: cSpell:ignore Tokio
author:
  name: Doug Fawley
  position: Google
---

Today, the gRPC project is excited to share its first preview release of
gRPC-Rust.  It can be found at
[crates.io/crates/grpc](https://crates.io/crates/grpc).  Documentation is
available on our website, [grpc.io](https://grpc.io/docs/languages/rust).  This
release is not recommended for production use at this time, but is being
released at an early stage to provide Rust programmers with an opportunity to
experiment with the APIs and ensure they will be acceptable for their needs.

## What is included

This release includes:

* Protobuf support using Google's [Protobuf-Rust
  library](https://github.com/protocolbuffers/protobuf) and tools.

  * Messages are generated from Protobuf-Rust via `protoc`.
  * gRPC generated RPC code using our `protoc` plugin.

* Low-level RPC API for creating interceptors and performing RPCs without the
  need for the protobuf generated code.

* Support for the [Tokio](https://tokio.rs/) [async
  runtime](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html#async-runtimes).
  * Future gRPC-Rust releases intend to work with any runtime; however, for this
    preview we are only targetting Tokio.

## Learn more

Documentation for this gRPC-Rust preview is now available on
[grpc.io](https://grpc.io/docs/languages/rust/).  The following resources are
available:

* [Generated code reference](https://grpc.io/docs/languages/rust/generated-code)
* [Quick start guide](https://grpc.io/docs/languages/rust/quickstart)
* [Basics tutorial](https://grpc.io/docs/languages/rust/basics) that covers each
  of the four RPC types.

## Contact the team

Please reach out to the team if you have any feedback or encounter any issues:

* Bugs/Feature Requests: [Github Repo](https://github.com/grpc/grpc-rust)
* Discussions: [Google Groups](https://groups.google.com/g/grpc-io)

## Join us at gRPConf 2026!

If you're interested in meeting the gRPC team, discussing related topics with
others in the industry, or maybe even sharing your own experiences or advice in
a talk, please mark your calendar for **Thursday, September 3rd**, when we'll be
holding this year's gRPC developer's conference at the [Computer History
Museum](https://computerhistory.org/) in Mountain View, CA.

* **Event Site:** [gRPConf](https://events.linuxfoundation.org/grpconf/)
* **CFP is open:** [Submit your talk!](https://events.linuxfoundation.org/grpconf/program/cfp/)
