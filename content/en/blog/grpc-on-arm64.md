---
title: Running gRPC and Protobuf on ARM64 (On Linux)
date: 2021-06-20
spelling: Tattermusch
author:
  name: Jan Tattermusch
  link: https://github.com/jtattermusch
---

ARM processors have recently been gaining importance in many areas of compute, including those that were traditionally considered to be an x86_64-only domain. Thanks to the momentum around the ARM ecosystem, we can expect adoption of ARM platforms to grow significantly. The same is true for providing software that supports ARM-based platforms.

Since the main purpose of gRPC and protocol buffers is to interconnect distributed systems, their role in supporting ARM compute is especially important. With the emergence of ARM Cloud computing, we expect many systems will actually be hybrid compositions of x86 and ARM servers, mixing and matching the qualities of each ecosystem as needed. gRPC and protocol buffers are the ideal building blocks that can enable users to build systems that span multiple architectures seamlessly.

To meet the increasing demand from gRPC users to support ARM, the gRPC team has decided to support selected ARM-based platforms officially and fully. Some time ago, we started an effort to test everything and fix any problems we encounter. **Today, we are happy to announce that gRPC and protocol buffers implementations in C++, C#, Go, Java, Node, PHP, Python and Ruby are ready for production workloads for ARM64 Linux** (see more details below).

The current state of things is best described by a list of general areas we completed:

- [Bugfixes/improvements] We put a number of fixes in place to make sure gRPC and protobuf work reliably on ARM64 Linux.
- [Package & Distribution] For the languages that provide binary architecture-specific packages, we added ARM64 Linux packages, and we started publishing them on every release as part of our standard release process. Having ready-to-use binary packages greatly improves the developer experience. For languages that don't ship using binary-packages, we tested that the build works as expected and that one can install gRPC and protobuf on ARM64 Linux without problems.
- [Continuous Testing] We invested significant resources setting up continuous testing ensuring that gRPC and protobuf are fully tested and prevent any future regressions. Testing large projects with many tests and support for multiple languages was definitely a challenge, especially since the open source ecosystem for testing on ARM architecture is still in its infancy, but we successfully tested gRPC and protobuf with a combination of cross-compilation, emulated tests and running tests on real hardware.

## Overview of gRPC and Protobuf support on ARM64 Linux

In the following table you can see the detailed status broken down by language. Each entry summarizes the support level for both gRPC and Protobuf on ARM64 Linux.

| Language        | continuously tested | distribution/packages                                                                                                                             | additional info                                                                                                                                                                                          |
|-----------------|---------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| C++             | Y                   | build from source using cmake or bazel (same approach as on x86)                                                                                  |                                                                                                                                                                                                          |
| C#              | Y                   | Grpc.Core nuget packages now have aarch64 Linux support. TODO: add min version supported                                                          | Grpc.Tools nuget package has now support for codegen on aarch64 linux.                                                                                                                                   |
| Go              | Y                   | Use the standard way of installing libraries in golang (same experience as on x86)                                                                |                                                                                                                                                                                                          |
| Java            | Y                   | Maven artifacts published with each release work well on aarch64 Linux                                                                            | aarch64 protoc and grpc-java protoc plugin are published with each release                                                                                                                               |
| Node/Javascript | Y                   | use existing npm packages (they are platform-independent)                                                                                         |                                                                                                                                                                                                          |
| PHP             | Y                   | Existing PECL and composer packages work well on Linux aarch64.                                                                                   |                                                                                                                                                                                                          |
| Python          | Y                   | pre-built wheels published with each release (aarch64 Linux) TODO: add min version supported                                                      | grpcio-tools package has now support for codegen on aarch64 Linux.                                                                                                                                       |
| Ruby            | Y                   | Pre-built native gems for aarch64 Linux not available yet. In order to use grpc-ruby and protobuf-ruby, users need to build the gems from source. | Continuous tests are in place and they are passing consistently, but we don't yet provide pre-build packages. gRPC and protobuf in ruby are safe to use, but the installation experience is suboptimal.  |

### ARM64 / aarch64 / ARMv8 terminology

While the terms ARM64, aarch64 and ARMv8 denote slightly different things, in practice they are often used interchangeably. For purposes of this article, they all mean essentially the same thing and they can be treated as synonyms.

### Official ARM64 support is currently Linux-only

At this point we only officially support gRPC and Protobuf on ARM64 on Linux. We do realize that there's demand for ARM64 support for other platforms as well (e.g. MacOS X with the new Apple M1 Silicon), but some of these platforms come with significant challenges (provisioning the hardware, lack of emulation, etc). Rather than delaying the ARM64 support release due to these complications, it made more sense to stay focused on delivering official ARM64 support to Linux first - so there we go.

## Appendix: list of changes/fixes/improvements

https://github.com/grpc/grpc/pull/25258 
https://github.com/grpc/grpc/pull/25418
https://github.com/grpc/grpc/pull/25453
https://github.com/grpc/grpc/pull/25517 
https://github.com/grpc/grpc/pull/25602 
https://github.com/grpc/grpc/pull/25717 
https://github.com/grpc/grpc/pull/25928 
https://github.com/grpc/grpc/pull/26136 
https://github.com/grpc/grpc/pull/26409 
https://github.com/grpc/grpc/pull/26416 
https://github.com/grpc/grpc/pull/26430 

https://github.com/grpc/grpc-java/pull/8113 
https://github.com/grpc/grpc-java/pull/7812 
https://github.com/grpc/grpc-java/pull/7822 

https://github.com/grpc/grpc-go/pull/4344 

https://github.com/protocolbuffers/protobuf/pull/8280
https://github.com/protocolbuffers/protobuf/pull/8391
https://github.com/protocolbuffers/protobuf/pull/8392
https://github.com/protocolbuffers/protobuf/pull/8485 
https://github.com/protocolbuffers/protobuf/pull/8501 
https://github.com/protocolbuffers/protobuf/pull/8544 
https://github.com/protocolbuffers/protobuf/pull/8638 


