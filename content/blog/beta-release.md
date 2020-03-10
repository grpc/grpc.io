---
title: gRPC releases Beta, opening door for use in production environments
attribution: Mugur Marculescu, gRPC
date: 2015-10-26
aliases: ["blog/beta_release"]
---

The gRPC team is excited to announce the immediate availability of gRPC Beta. This release marks an important point in API stability and going forward most API changes are expected to be additive in nature. This milestone opens the door for gRPC use in production environments.

We’re also taking a big step forward in improving the installation process. Over the past few weeks we’ve rolled out gRPC packages to <a href="https://packages.debian.org/jessie-backports/libgrpc0">Debian Stable/Backports</a>. Installation in most cases is now a two line install using the Debian package and available language specific package managers (<a href="https://search.maven.org/#artifactdetails%7Cio.grpc%7Cgrpc-core%7C0.9.0%7Cjar">maven</a>, <a href="https://pypi.python.org/pypi/grpcio">pip</a>, <a href="https://rubygems.org/gems/grpc">gem</a>, <a href="https://packagist.org/packages/grpc/grpc">composer</a>, <a href="https://pecl.php.net/package/gRPC">pecl</a>, <a href="https://www.npmjs.com/package/grpc">npm</a>, <a href="https://www.nuget.org/packages/Grpc/">nuget</a>, [pod](https://cocoapods.org/pods/gRPC)). In addition [gRPC docker images](https://hub.docker.com/r/grpc) are now available on Docker Hub.


We’ve updated the [documentation](/docs) on grpc.io to reflect the latest changes and released additional language-specific [reference docs](/docs/reference). See what’s changed with the Beta release in the release notes on GitHub for [Java](https://github.com/grpc/grpc-java/releases/tag/v0.9.0), [Go](https://godoc.org/google.golang.org/grpc), and [all other](https://github.com/grpc/grpc/releases/tag/release-0_11_0) languages.

In keeping in line with our [principles](../principles) and goal to enable highly performant and scalable APIs and microservices on top of HTTP/2, in the coming months, the focus of the gRPC project will be to keep improving performance and stability and adding carefully chosen features for production use cases. Documentation will also be clarified and will continue to improve with new examples and guides.


We’ve been very excited to see the community response to gRPC and the various projects starting to use it ([etcd v3 experimental API](https://coreos.com/blog/etcd-2.2), [grpc-gateway](https://github.com/gengo/grpc-gateway) for RESTful APIs and others).

We really want to thank everyone who contributed code, gave presentations, adopted the technology and engaged in the community. With your help support we look forward to the 1.0!
