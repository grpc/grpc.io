# @grpc/grpc-js 1.0

Today we are excited to announce the release of version 1.0 of [@grpc/grpc-js](https://www.npmjs.com/package/@grpc/grpc-js). This library is a reimplementation of the original [grpc](https://www.npmjs.com/package/grpc) library for Node.js, but purely in TypeScript, no longer depending on native C++ code that requires complex compilation and installation procedures.

With this release, the original grpc library is deprecated. We will continue releasing new binary packages for new versions of the Node and Electron runtimes, but it will not receive any new features.

We worked hard to bring @grpc/grpc-js to you, with a feature set that we believe should fit most, if not all usage cases:

## Features

+   Clients
+   Automatic reconnection
+   Servers
+   Streaming
+   Metadata
+   Partial compression support: clients can decompress response messages
+   Pick first and round robin load balancing policies
+   Client Interceptors
+   Connection Keepalives
+   HTTP Connect support (proxies)

## Which library should I use?

As of today, we recommend that all users should use @grpc/grpc-js.

If you need some advanced features that have not yet been added to @grpc/grpc-js, such as full compression support or support for other load balancing policies, you should continue using the original native grpc library, and file [feature requests](https://github.com/grpc/grpc-node/issues/new?template=feature_request.md) to let us know which features you are missing the most. 