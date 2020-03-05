---
title: About gRPC
---

gRPC is a modern open source high performance RPC framework that can run in any
environment. It can efficiently connect services in and across data centers with
pluggable support for load balancing, tracing, health checking and
authentication. It is also applicable in last mile of distributed computing to
connect devices, mobile applications and browsers to backend services.

**The main usage scenarios:**

* Efficiently connecting polyglot services in microservices style architecture
* Connecting mobile devices, browser clients to backend services
* Generating efficient client libraries

**Core Features that make it awesome:**

* Idiomatic client libraries in 10 languages
* Highly efficient on wire and with a simple service definition framework
* Bi-directional streaming with http/2 based transport
* Pluggable auth, tracing, load balancing and health checking

<hr>

## Who’s using gRPC and why?

Many companies are already using gRPC for connecting multiple services in their
environments. The use case varies from connecting a handful of services to
hundreds of services across various languages in on-prem or cloud environments.
Below are details and quotes from some of our early adopters.

Check out what people are saying below.

<div class="testimonialrow">
  <div class="testimonialsection">
    <div class="testimonialimage">
      <a href="https://www.youtube.com/watch?v=-2sWDr3Z0Wo"><img src="../img/square-icon.png" style="width:45%"/></a>
    </div>
    <div>
      <span class="testimonialquote">“ </span>
      At Square, we have been collaborating with Google so that we can replace all uses of our custom RPC solution to use gRPC.  We decided to move to gRPC because of its open support for multiple platforms, the demonstrated performance of the protocol, and the ability to customize and adapt it to our network.  Developers at Square are looking forward to being able to take advantage of writing streaming APIs and in the future, push gRPC to the edges of the network for integration with mobile clients and third party APIs.
    </div>
  </div>

  <div class="testimonialsection">
    <div class="testimonialimage">
      <a href="https://github.com/Netflix/ribbon"><img src="../img/netflix-logo.png" /></a>
    </div>
    <div>
      <span class="testimonialquote"> “ </span>
      In our initial use of gRPC we've been able to extend it easily to live within our opinionated ecosystem.  Further, we've had great success making improvements directly to gRPC through pull requests and interactions with Google's team that manages the project.  We expect to see many improvements to developer productivity, and the ability to allow development in non-JVM languages as a result of adopting gRPC.
    </div>
  </div>

  <div class="testimonialsection">
    <div class="testimonialimage">
      <a href="https://blog.gopheracademy.com/advent-2015/etcd-distributed-key-value-store-with-grpc-http2/">
        <img src="../img/coreos-1.png" style="width:30%"/>
      </a>
    </div>
    <div>
      <span class="testimonialquote">“ </span>
      At CoreOS we are excited by the gRPC v1.0 release and the opportunities it opens up for people consuming and building what we like to call Google Infrastructure for Everyone Else. Today gRPC is in use in a number of our critical open source projects such as the etcd consensus database and the rkt container engine.
    </div>
  </div>
</div>

<div class="testimonialrow">
  <div class="testimonialsection">
    <div class="testimonialimage">
      <a href="https://github.com/cockroachdb/cockroach"><img src="../img/cockroach-1.png"/></a>
    </div>
    <div>
      <span class="testimonialquote">“ </span>
      Our switch from a home-grown RPC system to gRPC was seamless. We quickly took advantage of the per-stream flow control to provide better scheduling of large RPCs over the same connection as small ones.
    </div>
  </div>

  <div class="testimonialsection">
    <div class="testimonialimage">
      <a href="https://github.com/CiscoDevNet/grpc-getting-started"><img src="../img/cisco.svg"/></a>
    </div>
    <div>
      <span class="testimonialquote">“ </span>
      With support for high performance bi-directional streaming, TLS based security, and a wide variety of programming languages, gRPC is an ideal unified transport protocol for model driven configuration and telemetry.
    </div>
  </div>

  <div class="testimonialsection">
    <div class="testimonialimage">
      <a href="http://www.carbon3d.com"><img src="../img/carbon3d.svg"/></a>
    </div>
    <div>
      <span class="testimonialquote">“ </span>
      Carbon3D uses gRPC to implement distributed processes both within and outside our 3D printers. We actually switched from using Thrift early on for a number of reasons including but not limited to robust support for multiple languages like C++, Nodejs and Python. Features like bi-directional streaming are a huge win in keeping our systems implementations simpler and correct. Lastly the gRPC team/community is very active and responsive which is also a key factor for us in selecting an open source technology for mission critical projects.
    </div>
  </div>
</div>

<div class="testimonialrow">
  <div class="testimonialsection">
    <div class="testimonialimage"><a href="https://www.wisc.edu/"><img src="../img/wisc-mad.jpg"/></a></div>
    <div>
      <span class="testimonialquote">“ </span>
      We've been using gRPC for both classes and research at University of Wisconsin. Students in our distributed systems class (CS 739) utilized many of its powerful features when building their own distributed systems. In addition, gRPC is a key component of our OpenLambda research project (https://www.open-lambda.org/) which aims to provide an open-source, low-latency, serverless computational framework.
    </div>
  </div>

  <div class="testimonialsection">
    <div class="testimonialimage"><a href="https://github.com/Juniper/open-nti"><img src="../img/juniperlogo.png"/></a></div>
    <div>
      <span class="testimonialquote">“ </span>
      <p>The fact that gRPC is built on HTTP/2 transport brings us native bi-directional streaming capabilities and flexible custom-metadata in request headers.  The first point is important for large payloadexchange and network telemetry scenarios while the latter enables us to expand and include capabilities including but not limited to various network element authentication mechanisms.</p>
      <p>In addition, the wide language binding support that gRPC/proto3 bringsenables us to provide a flexible and rapid development environment for both internal and external consumers.</p>
      <p>Last but not least, while there are a number of network communicationprotocols for configuration, operational state retrieval and network telemetry, gRPC provides us with a unified flexible protocol and transport to ease client/server interaction.</p>
    </div>
  </div>

  <div class="testimonialsection">
    <div class="testimonialimage"><a href="http://www.pingcap.com"><img src="../img/pingcap5.png"/></a></div>
    <div>
      <span class="testimonialquote">“ </span>
      At PingCAP, we use gRPC in almost every project that involves interactions or communications through network. As has been proven, gRPC has well met our demands in terms of performance and usability. We also provide a production-ready gRPC library for Rust.
    </div>
  </div>
</div>

<div class="clearfix"></div>

## Officially supported platforms

<!-- Generated using the data in data/platforms.yaml -->
{{< supported-platforms >}}

## The story behind gRPC

Google has been using a single general-purpose RPC infrastructure called Stubby
to connect the large number of microservices running within and across our data
centers for over a decade. Our internal systems have long embraced the
microservice architecture gaining popularity today. Stubby has powered all of
Google’s microservices interconnect for over a decade and is the RPC backbone
behind every Google service that you use today. In March 2015, we decided to
build the next version of Stubby in the open so we can share our learnings with
the industry and collaborate with them to build the next version of Stubby both
for microservices inside and outside Google but also for last mile of computing
(mobile, web and IOT).

For more background on why we created gRPC, see [gRPC Motivation and Design
Principles blog](/blog/principles).
