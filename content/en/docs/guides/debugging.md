---
title: Debugging
description: >-
  Explains the debugging process of gRPC applications using grpcdebug
---

### Overview
[grpcdebug] is a command line tool within the gRPC ecosystem designed to assist developers in debugging and troubleshooting gRPC services. grpcdebug fetches the internal states of the gRPC library from the application via gRPC protocol and provides a human-friendly UX to browse them. Currently, it supports [Channelz]/[Health] Checking/CSDS (aka. [admin services]). In other words, it can fetch statistics about how many RPCs have being sent or failed on a given gRPC channel, it can inspect address resolution results, it can dump the active xDS configuration that directs the routing of RPCs.

### Language examples

| Language | Example          | Notes                                                            |
|----------|------------------|------------------------------------------------------------------|
| C++      | [C++ Example]    |                                                                  |
| Go       | [Go Example]     | [Go test server implementing admin services from grpcdebug docs] |
| Java     | [Java Example]   |                                                                  |

### References

* [grpcdebug installation]
* [grpcdebug quick start]


[grpcdebug]: https://github.com/grpc-ecosystem/grpcdebug
[Health]:https://github.com/grpc/grpc/blob/master/src/proto/grpc/health/v1/health.proto
[Channelz]: https://github.com/grpc/proposal/blob/master/A14-channelz.md
[admin services]: https://github.com/grpc/proposal/blob/master/A38-admin-interface-api.md
[C++ Example]: https://github.com/grpc/grpc/tree/master/examples/cpp/debugging#using-grpcdebug
[Go Example]: https://github.com/grpc-ecosystem/grpcdebug?tab=readme-ov-file#quick-start
[Java Example]: https://github.com/grpc/grpc-java/tree/master/examples/example-debug#using-grpcdebug
[grpcdebug installation]: https://github.com/grpc-ecosystem/grpcdebug?tab=readme-ov-file#installation
[grpcdebug quick start]: https://github.com/grpc-ecosystem/grpcdebug?tab=readme-ov-file#quick-start
[Go test server implementing admin services from grpcdebug docs]: https://github.com/grpc-ecosystem/grpcdebug/tree/main/internal/testing/testserver