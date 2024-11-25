---
title: gRPC Video Hub
linkTitle: Videos
description: Explore & Master gRPC
menu:
  main: {weight: 4}
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

## Overview and Getting started with gRPC
---

- [[gRPConf 2024 Keynote] Overview of gRPC | Ivy Zhuang, Google](https://youtu.be/sImWl7JyK_Q)

  Prepare to be immersed in the world of gRPC as we embark on a comprehensive exploration of its architecture and terminology. This session will serve as your launchpad into a day filled with rich topics and advanced use cases within the vibrant gRPC ecosystem.By the end of this session, you'll have a renewed appreciation for the incredible capabilities that gRPC has to offer.

<br>

- [gRPC in 5 minutes | Eric Anderson & Ivy Zhuang, Google](https://youtu.be/njC24ts24Pg)

  gRPC is a modern high performance Remote Procedure Call (RPC) framework that can run across languages. gRPC has been de facto the industry standard for RPC frameworks, which is used in organizations in and outside of Google to power use cases from microservices to the “last mile” of computing (mobile, web, and Internet of Things).

<br>

- [Getting Started with gRPC | Easwar Swaminathan & Arvind Bright, Google](https://youtu.be/cSGBbwvW1y4)

  This talk covers the architecture, basic features, and how to start using gRPC.  You can expect to come out of this session with a high-level understanding of gRPC core functions and the basic coding components needed to incorporate gRPC into your applications.

<br>

- [Ten Years of gRPC | Jung-Yu (Gina) Yeh & Richard Belleville, Google](https://youtu.be/5dMK5OW6WSw)

  Over the past ten years, gRPC has become indispensable to a breathtaking array of engineering organizations. Join the maintainers look back at how gRPC got to where it is today, the way the software has grown, and the community along with it. Then, see what's in store for the future of gRPC in the decades to come.

<br>

## Deep dive into gRPC and its applications
---

- [gRPC Performance and Testing: a Maintainer Perspective | Ashley Zhang & Adam Heller, Google](https://youtu.be/uQh9ZVGkrak)

  In an environment where every microsecond of latency and every CPU cycle counts, how do we keep gRPC performant, stable, and feature-rich? We'll give you an overview of what goes into producing reliable, performance-tuned gRPC libraries. This maintainer talk covers the how and why we focus on performance, gRPC's testing infrastructure, and some of our testing and performance philosophies. You'll also get a sneak preview of improvements in the pipeline for future releases.

<br>

- [Load Balancing in gRPC | Easwar Swaminathan, Google](https://youtu.be/G6PRjmXuBG8)

  In this session, we will cover the following: 
    - **Basics of client-side load balancing support in gRPC**: Here, we will cover the interaction between the gRPC channel and the load balancing policy. We will also go over the load balancing API in gRPC that allows our users to implement their own policies. 
    - **Overview of supported load balancing policies**: gRPC ships with a bunch of load balancing policy implementations. We will go through a subset of them and talk about ideal deployment scenarios for each of them. 
    - **Custom load balancing policy support in gRPC**: gRPC supports configuration of custom load balancing policies on the client by the control plane.

<br>

- [gRPC Metadata Limits: The Good, the Bad, and the Ugly | Alisha Nanda, Google](https://youtu.be/psYQFbPgIOI)

  gRPC metadata is a useful mechanism for implementing authentication, tracing, and application-specific features. It is important that applications configure a limit on received metadata size, since metadata is not flow-controlled and large amounts can severely degrade performance. But configuring metadata limits can be tricky - what if the client accidentally starts sending too much metadata? Or worse, what if some proxy between client and server configures a lower metadata limit than the server? This talk will explore these questions and more, including how applications can learn to protect against such issues in the future.

<br>

- [gRPC Weighted Round Robin LB Policy | WRR | EDF Scheduling | Yifei (Ivy) Zhuang, Google](https://youtu.be/7LYvl-nr0t8)

  Weighted round robin load balancing policy is particularly useful for heterogeneous server environments, and it provides a flexible way to optimize your gRPC service's performance and resource utilization. This video delves into the inner workings of gRPC's WRR LB policy, and explains how the underlying earliest deadline scheduling and the enhanced static stride scheduling algorithms comes into play. Additionally, it walks through client/server configuration steps necessary to enable weighted round robin within your gRPC services.

<br>

- [OpenTelemetry - The future of Observability | Yash Tibrewal | Google](https://youtu.be/L6FAtc8N8Vk)

  OpenTelemetry is the new open-source, vendor-neutral instrumentation ecosystem that is the exciting future of telemetry. This talk will teach you the basics including how to instrument applications with OpenTelemetry and how to export the metrics using an exporter like Prometheus.

<br>

- [Supporting xDS in the gRPC Client Architecture | Mark Roth, Google.](https://youtu.be/Z3X6kD_1SFo)

  The xDS API was originally created as part of the Envoy project, so its structure models Envoy's architecture.  The gRPC client architecture is significantly different from Envoy's, so supporting xDS in gRPC imposed some significant challenges.  This talk describes how we bridged that gap, leveraging (and sometimes extending) existing gRPC interfaces like the resolver and LB policy APIs to provide the semantics expected by the xDS API.

<br>

- [Leveling Up your Service Mesh with gRPC | Ivy Zhuang & Richard Belleville, Google](https://youtu.be/B8gfu5bs2Pw)

  Service mesh has changed how we deploy and maintain distributed systems, bringing us advanced traffic management, end-to-end security, and much more. However, these advances typically use sidecar proxies running alongside every workload, eating up CPU and increasing end-to-end latency.gRPC proxyless service mesh delivers the benefits of a service mesh while reducing the challenges associated with sidecar proxies. In this talk, you'll learn how to combine a gRPC data plane with your xDS-compatible service mesh control plane of choice.

<br>

## User stories
---

- [How Netflix Makes gRPC Easy to Serve, Consume, and Operate Benjamin Fedorka, Netflix](https://youtu.be/ywrkBqq_LLA)

  In this talk, you'll learn how Netflix makes gRPC easy to serve, consume and operate.

<br>

- [Adapting our xDS control plane for proxyless gRPC | Antoine Tollenaere, Datadog](https://youtu.be/gc3kNMvgrHQ)

  This talk describes about adapting the xDS control plane for proxyless gRPC.

<br>

- [Enhancing gRPC micro-services | Holly Casaletto and Yucong Sun, Coinbase](https://youtu.be/GDJrw36wwWY)

  A case study of enhancing gRPC micro-services for supporting high throughput, low latency trading - Holly Casaletto and Yucong Sun, Coinbase

<br>

</div>

{{< page/toc placement="sidebar" >}}

</div>

{{< page/page-meta-links >}}

</div>
