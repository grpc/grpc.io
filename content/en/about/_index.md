---
title: About gRPC
linkTitle: About
description: Who is using gRPC and why
menu:
  main: {weight: 1}
---

{{< blocks/cover image_anchor="top" height="sm" color="primary" >}}
{{< page/header >}}
{{< /blocks/cover >}}

<div class="container l-container--padded">

<div class="row">
{{< page/toc collapsed=true placement="inline" >}}
</div>

<div class="row">
<div class="col-12 col-lg-8">

{{< youtube id="5dMK5OW6WSw" class="youtube-video" title="Ten Years of gRPC" >}}

gRPC is a modern open source high performance Remote Procedure Call (RPC)
framework that can run in any environment. It can efficiently connect services
in and across data centers with pluggable support for load balancing, tracing,
health checking and authentication. It is also applicable in last mile of
distributed computing to connect devices, mobile applications and browsers to
backend services.

### The main usage scenarios

* Efficiently connecting polyglot services in microservices style architecture
* Connecting mobile devices, browser clients to backend services
* Generating efficient client libraries

### Core features that make it awesome

* Idiomatic client libraries in 11 languages
* Highly efficient on wire and with a simple service definition framework
* Bi-directional streaming with http/2 based transport
* Pluggable auth, tracing, load balancing and health checking

## Who’s using gRPC and why?

Many companies are already using gRPC for connecting multiple services in their
environments. The use case varies from connecting a handful of services to
hundreds of services across various languages in on-prem or cloud environments.
Below are details and quotes from some of our early adopters.

Check out what people are saying below.

{{< about/testimonials >}}

## The story behind gRPC

gRPC was initially created by Google, which has used a single general-purpose
RPC infrastructure called **Stubby** to connect the large number of microservices
running within and across its data centers for over a decade. In March 2015,
Google decided to build the next version of Stubby and make it open source. The
result was gRPC, which is now used in many organizations outside of
Google to power use cases from microservices to the "last mile" of computing
(mobile, web, and Internet of Things).

For more background on why we created gRPC, see the [gRPC Motivation and Design
Principles](/blog/principles/) on the [gRPC blog](/blog/).

{{% alert title="Note" color="info" %}}
<a name="officially-supported-languages-and-platforms"></a>

Our table of **officially supported languages and platforms** has moved!
See [Official support]({{<relref "docs#official-support">}}).
{{% /alert %}}

</div>

{{< page/toc placement="sidebar" >}}

</div>

{{< page/page-meta-links >}}

</div>
