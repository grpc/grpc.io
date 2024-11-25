---
title: Showcase
description: Customer success stories, developers stories, and more
url_use_grpc: https://www.cncf.io/case-studies/?_sft_lf-project=grpc
spelling: cSpell:ignore youtube Kubernetes Nulab Protop
customer_success_stories:
  - title: >
      [Salesforce](https://www.cncf.io/case-studies/salesforce/)
    desc: How gRPC is enabling Salesforce’s unified interoperability strategy.
  - title: >
      [Mux](https://www.cncf.io/case-studies/mux/)
    desc: How cloud native technology helps Mux simplify online video streaming.
  - title: >
      [Nulab](https://www.cncf.io/case-studies/nulab/)
    desc: >
      How the productivity software company Nulab boosted its own productivity
      with microservices and Kubernetes.
menu:
  main: {weight: 5}
---

{{< blocks/cover height="sm" color="primary" >}}
{{< page/header >}}
{{< /blocks/cover >}}

<div class="container l-container--padded">

<div class="row">
{{< page/toc collapsed=true placement="inline" >}}
</div>

<div class="row">
<div class="col-12 col-lg-8">

## Customer success stories

Here are a few of the customers who [successfully adopted **gRPC**][use-of-grpc]
and other [CNCF technologies](https://www.cncf.io/projects/) in the past year

{{% cards "customer_success_stories" %}}

<div class="text-center my-4">
<a class="btn btn-secondary"
    href="{{< param url_use_grpc >}}"
    target="_blank"
    rel="noopener"
    >View all</a>
</div>

There are [many CNCF projects](https://www.cncf.io/projects/) of which gRPC is
one. For a complete list of customer stories describing the successful adoption
of CNCF technologies, see the [CNCF case studies][] page.

## Developer stories

Developer stories cover a variety of technical subjects related to gRPC. You can
find developer stories for your [preferred language](/docs/languages/) on each
**language-specific landing page**.

<div class="l-dev-story-buttons text-center">

- [Go]({{< relref "go#dev-stories" >}})
<!-- TODO: add once section has dev stories: [C++]({{< relref "cpp#dev-stories" >}}) -->
- [Java](/docs/languages/java#dev-stories)
<!-- TODO: add once section has dev stories: - [Python]({{< relref "python#dev-stories" >}}) -->
<!-- TODO: add once section has dev stories: - [C#]({{< relref "csharp#dev-stories" >}}) -->
- [Kotlin](/docs/languages/kotlin#dev-stories)
- [<i class="fas fa-ellipsis-h"></i>]({{< relref "languages" >}})
</div>

Other developer stories are provided next.
- **Adapting our xDS control plane for proxyless gRPC**
  <a class="o-icon" href="https://youtu.be/gc3kNMvgrHQ"><i class="fab fa-youtube"></i></a><br>
  by Antoine Tollenaere, Datadog
- **Building SpiceDB: a gRPC-first database**
  <a class="o-icon" href="https://youtu.be/v_e2ExQwphQ"><i class="fab fa-youtube"></i></a><br>
  by Jimmy Zelinskie, authzed
- **Enhancing gRPC micro-services**
  <a class="o-icon" href="https://youtu.be/GDJrw36wwWY"><i class="fab fa-youtube"></i></a><br>
  by Holly Casaletto and Yucong Sun, Coinbase
- **[Expedia Group Case Study: Bootiful APIs With GraphQL and Kotlin][Expedia]**,
  by [Anton Arhipov](https://blog.jetbrains.com/author/antonarhipov),
  [JetBrains](https://www.jetbrains.com/),
  <span title="2020-12-13">December 2020</span>.
- **[DoorDash Case Study: Building Scalable Backend Services with Kotlin][DoorDash]**,
  by [Alina Dolgikh](https://blog.jetbrains.com/author/alinadolgikh),
  [JetBrains](https://www.jetbrains.com/),
  <span title="2020-12-06">December 2020</span>.
- **[Road to gRPC](https://blog.cloudflare.com/road-to-grpc/)**
  by [Junho Choi](https://blog.cloudflare.com/author/junho/) et al.,
  [Cloudflare](https://www.cloudflare.com/). October 26, 2020.
- [**How GIPHY’s Public API Integrates with gRPC Services**](https://engineering.giphy.com/how-giphys-public-api-integrates-with-grpc-services/)<br>
  by Serhii Kushch. August 13, 2020.
- **A Simplified Service Mesh With gRPC**
  <a class="o-icon" href="https://youtu.be/9alMEeTxsMA"><i class="fab fa-youtube"></i></a>
  <a href="https://static.sched.com/hosted_files/grpcconf20/ae/A%20Simplified%20Service%20Mesh%20with%20gRPC.pdf"><i class="fas fa-file"></i></a><br>
  A [gRPC Conf 2020 presentation](https://sched.co/cRfZ)
  by Srini Polavarapu, Engineering Manager, Google
- **Protop: A Package Manager for gRPC and Protocol Buffers**
  <a class="o-icon" href="https://youtu.be/q1KWl-vPi6w"><i class="fab fa-youtube"></i></a>
  <a href="https://static.sched.com/hosted_files/grpcconf20/6b/protop%20-%20a%20package%20manager%20for%20protobufs.pdf"><i class="fas fa-file"></i></a><br>
  A [gRPC Conf 2020 presentation](https://sched.co/cRfo)
  by Jeffery Shivers, Toast, Inc
- **Service Interoperability With gRPC: gRPC in Action**
  <a class="o-icon" href="https://youtu.be/MLS7TFHrn_c"><i class="fab fa-youtube"></i></a>
  <a class="o-icon" href="https://static.sched.com/hosted_files/grpcconf20/d3/Service%20Interoperability%20with%20gRPC.pdf"><i class="fas fa-file"></i></a><br>
  A [gRPC Conf 2020 presentation](https://sched.co/cRfl)
  by Varun Gupta & Tuhin Kanti Sharma, Salesforce.

## More

- [gRPC Conf 2020 presentation videos][]. Looking for slides? Select the
  presentation's entry in the [schedule][] page. If the author provided slides,
  you'll find them below the author's bio.

</div>

{{< page/toc placement="sidebar" >}}

</div>

{{< page/page-meta-links >}}

</div>

[CNCF case studies]: https://www.cncf.io/case-studies/
[DoorDash]: https://blog.jetbrains.com/kotlin/2020/12/doordash-building-scalable-backend-services-with-kotlin/
[Expedia]: https://blog.jetbrains.com/kotlin/2020/12/expedia-group-bootiful-apis-with-graphql-and-kotlin/
[gRPC Conf 2020 presentation videos]: https://www.youtube.com/playlist?list=PLj6h78yzYM2NN72UX_fdmc5CZI-D5qfJL
[schedule]: https://events.linuxfoundation.org/grpc-conf/program/schedule/
[use-of-gRPC]: {{< param url_use_grpc >}}
