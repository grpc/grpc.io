---
title: Videos
description: Links of gRPC youtube videos
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

Following are the links of youtube videos that helped to get familiar with gRPC :

- [Ten Years of gRPC | Jung-Yu (Gina) Yeh & Richard Belleville, Google](https://youtu.be/5dMK5OW6WSw)
Over the past ten years, gRPC has become indispensable to a breathtaking array of engineering organizations. Join the maintainers look back at how gRPC got to where it is today, the way the software has grown, and the community along with it. Then, see what's in store for the future of gRPC in the decades to come.

- [[gRPConf 2024 Keynote] Overview of gRPC | Ivy Zhuang, Google](https://youtu.be/sImWl7JyK_Q)Prepare to be immersed in the world of gRPC as we embark on a comprehensive exploration of its architecture and terminology. This session will serve as your launchpad into a day filled with rich topics and advanced use cases within the vibrant gRPC ecosystem.By the end of this session, you'll have a renewed appreciation for the incredible capabilities that gRPC has to offer.

- [gRPC in 5 minutes | Eric Anderson & Ivy Zhuang, Google](https://youtu.be/njC24ts24Pg)gRPC is a modern high performance Remote Procedure Call (RPC) framework that can run across languages. gRPC has been de facto the industry standard for RPC frameworks, which is used in organizations in and outside of Google to power use cases from microservices to the “last mile” of computing (mobile, web, and Internet of Things).

- [Getting Started with gRPC | Easwar Swaminathan & Arvind Bright, Google](https://youtu.be/cSGBbwvW1y4)This talk covers the architecture, basic features, and how to start using gRPC.  You can expect to come out of this session with a high-level understanding of gRPC core functions and the basic coding components needed to incorporate gRPC into your applications.

- [gRPC Performance and Testing: a Maintainer Perspective | Ashley Zhang & Adam Heller, Google](https://youtu.be/uQh9ZVGkrak)In an environment where every microsecond of latency and every CPU cycle counts, how do we keep gRPC performant, stable, and feature-rich? We'll give you an overview of what goes into producing reliable, performance-tuned gRPC libraries. This maintainer talk covers the how and why we focus on performance, gRPC's testing infrastructure, and some of our testing and performance philosophies. You'll also get a sneak preview of improvements in the pipeline for future releases.

- [Load Balancing in gRPC | Easwar Swaminathan, Google](https://youtu.be/G6PRjmXuBG8)In this session, we will cover Basics of client-side load balancing support in gRPC, Overview of supported load balancing policies, Custom load balancing policy support in gRPC.

- [gRPC Metadata Limits: The Good, the Bad, and the Ugly | Alisha Nanda, Google](https://youtu.be/psYQFbPgIOI)gRPC metadata is a useful mechanism for implementing authentication, tracing, and application-specific features. It is important that applications configure a limit on received metadata size, since metadata is not flow-controlled and large amounts can severely degrade performance. But configuring metadata limits can be tricky - what if the client accidentally starts sending too much metadata? Or worse, what if some proxy between client and server configures a lower metadata limit than the server? This talk will explore these questions and more, including how applications can learn to protect against such issues in the future.

</div>

{{< page/toc placement="sidebar" >}}

</div>

{{< page/page-meta-links >}}

</div>
