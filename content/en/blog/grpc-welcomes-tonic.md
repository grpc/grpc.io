---
title: gRPC Welcomes Tonic!
date: 2026-05-21
author:
  name: Doug Fawley
---

As Lucio Franco [pre-announced on his
blog](https://luciofranco.com/blog/tonic-joins-grpc/) this week, we have now
officially moved the Tonic project and its repo into the [CNCF](http://cncf.io)
and [the gRPC project's github organization](http://github.com/grpc/grpc-rust).
We have been working together to coordinate this over the last two years, and
expect to continue to work together in the future as well.

If you're a tonic user and are wondering what this means to you:

* In the short term, hopefully nothing at all!  The tonic project will continue
  to operate as it did before.  Old links to github commits, issues, etc should
  continue to work.  tonic is currently not accepting any significant new
  features, but does provide releases for bug fixes, and that status will
  continue for the foreseeable future.
* In the next few months, we intend to release the `grpc` crate as a
  production-ready, long-term replacement for Tonic users.  This crate will
  provide all the advanced features available in our other gRPC libraries like
  connection management and client-side load balancing, and eventually [xDS /
  envoy support](http://envoyproxy.io) for [Proxyless Service Mesh
  (PSM)](https://docs.cloud.google.com/service-mesh/docs/service-routing/proxyless-overview).
  The tonic codegen interface will continue to be supported to allow users to
  upgrade to the new transport implementation without needing to rewrite their
  application.
* Going forward, you can expect the gRPC team to continue adding new features
  and providing ongoing maintenance of the `grpc` crate, matching our other
  supported languages.

Please let us know on our [mailing list](https://groups.google.com/g/grpc-io) or
in a github issue if you encounter any problems related to this change.  Thank
you!

## Join us at gRPConf 2026!

If you're interested in meeting the gRPC team, discussing related topics with
others in the industry, or maybe even sharing your own experiences or advice in
a talk, please mark your calendar for **Thursday, September 3rd**, when we'll be
holding this year's gRPC developer's conference at the [Computer History
Museum](https://computerhistory.org/) in Mountain View, CA.

* **Event Site:** [gRPConf](https://events.linuxfoundation.org/grpconf/)
* **CFP is open:** [Submit your talk!](https://events.linuxfoundation.org/grpconf/program/cfp/)
