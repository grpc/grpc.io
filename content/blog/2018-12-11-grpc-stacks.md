---
author:  Carl Mastrangelo
author-link: https://carlmastrangelo.com/
date: "2018-12-11T00:00:00Z"
published: true
title: Visualizing gRPC Language Stacks
url: blog/grpc-stacks
---

Here is a high level overview of the gRPC Stacks.  Each of the **10** default languages supported by gRPC has multiple layers, allowing you to customize what pieces you want in your application.

<!--more-->

There are three main stacks in gRPC: C-core, Go, and Java.  Most of the languages are thin wrappers on top of the [C-based](https://github.com/grpc/grpc/tree/master/src/core) gRPC core library:

### Wrapped Languages:

<p><img src="/img/grpc-core-stack.svg" alt="gRPC Core Stack" style="max-width: 800px" /></p>

For example, a Python application calls into the generated Python stubs.  These calls pass through interceptors, and into the wrapping library where the calls are translated into C calls.  The gRPC C-core will encode the RPC as HTTP/2, optionally encrypt the data with TLS, and then write it to the network.

One of the cool things about gRPC is that you can swap these pieces out.  For example, you could use C# instead, and use an In-Process transport.  This would save you from having to go all the way down to the OS network layer.   Another example is trying out the QUIC protocol, which allows you to open new connections quickly.  Being able to run over a variety of transports based on the environment makes gRPC really flexible.

For each of the wrapped languages, the default HTTP/2 implementation is built into the C-core library, so there is no need to include an outside one.  However, as you can see, it is possible to bring your own (such as with Cronet, the Chrome networking library).

### Go

In [gRPC-Go](https://github.com/grpc/grpc-go), the stack is much simpler, due to not having to support so many configurations.  Here is a high level overview of the Go stack:

<p><img src="/img/grpc-go-stack.svg" alt="gRPC Go Stack" style="max-width: 800px" /></p>

The structure is a little different here.  Since there is only one language, the flow from the top of the stack to the bottom is more linear.  Unlike wrapped languages, gRPC Go can use either its own HTTP/2 implementation, or the Go `net/http` package.


### Java

Here is a high level overview of the [gRPC-Java](https://github.com/grpc/grpc-java) stack:

<p><img src="/img/grpc-java-stack.svg" alt="gRPC Java Stack" style="max-width: 800px" /></p>

Again, the structure is a little different.  Java supports HTTP/2, QUIC, and In Process like the C-core.  Unlike the C-Core though, applications commonly can bypass the generated stubs and interceptors, and speak directly to the Java Core library.  Each structure is slightly different based on the needs of each language implementation of gRPC.  Also unlike wrapped languages, gRPC Java separates the HTTP/2 implementation into pluggable libraries (such as Netty, OkHttp, or Cronet). 
