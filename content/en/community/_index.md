---
title: Community
spelling: cSpell:ignore grpcio grpcmeetings subreddit
main_channels:
  - title: >
      <a href="https://twitter.com/grpcio" target="_blank" rel="noopener"><i class="fab
      fa-twitter"></i>&nbsp;Twitter</a>
    desc: >
      Follow us at [@grpcio][] for real-time news on blogs posts, events, and
      more.
  - title: >
      <a href="https://groups.google.com/forum/#!forum/grpc-io" target="_blank" rel="noopener"><i class="fab fa-google"></i>&nbsp;Google Group</a>
    desc: >
      Join the [grpc-io][] forum to ask questions and get the latest
      developer news, including [gRFCs][].
other_channels:
  - title: >
      <a href="https://gitter.im/grpc/grpc"
        target="_blank" rel="noopener"><i class="fab
        fa-gitter"></i>&nbsp;Gitter</a>
    desc: >
      Chat with other gRPC developers in the
      [`grpc/grpc`](https://gitter.im/grpc/grpc) community.
  - title: >
      <a href="https://stackoverflow.com/questions/tagged/grpc+protoc"
        target="_blank" rel="noopener"><i class="fab
        fa-stack-overflow"></i>&nbsp;Stack Overflow</a>
    desc: >
      Ask technical questions about [gRPC][grpc-tag] & [protoc][protoc-tag], and
      find answers.
  - title: >
      <a href="https://www.reddit.com/r/grpc/"
        target="_blank" rel="noopener"><i class="fab
        fa-reddit"></i>&nbsp;Reddit</a>
    desc: >
      Consult the [`r/grpc`](https://www.reddit.com/r/grpc/) subreddit for
      discussions related to gRPC.
meetup:
  - title: >
      <a href="https://www.reddit.com/r/grpc/"
        target="_blank" rel="noopener"><i class="fab
        fa-meetup"></i>&nbsp;Meetup</a>
    desc: >
      Join us [online][gRPCio] for project updates, live demos and more.
---

<style>
h2 { padding: 1rem 0 !important; }
h3 { padding: 0.5rem 0 !important; }
</style>

{{< blocks/cover color="primary" height="sm" >}}
{{< page/header >}}
{{< /blocks/cover >}}

<div class="container l-container--padded">

<div class="row">
{{< page/toc collapsed=true placement="inline" >}}
</div>

<div class="row">
<div class="col-12 col-lg-8">

Welcome to our active community of developers who are using and enhancing gRPC,
and building valuable integrations of gRPC with other software systems.

{{% alert color="success" %}}
  The gRPC community values respect and inclusiveness. We enforce our [Code of
  Conduct][] in all interactions.

  [Code of Conduct]: https://github.com/grpc/grpc.io/blob/main/CODE-OF-CONDUCT.md
{{% /alert %}}



## Stay informed

Be the first to know! Follow these active channels for the gRPC announcements:

{{% cards "main_channels" %}}

## Join the conversation

The [grpc-io][] forum, mentioned above, is a great place to ask technical
questions and engage in discussions with other gRPC developers.

The following channels, though less actively monitored, are also good places to
exchange with developers and find answers to your gRPC questions:

{{% cards "other_channels" %}}

### Community meetings

Get fresh news, and come talk with gRPC developers and other community members
at one of our regular online community meetings.

{{% cards "meetup" %}}

For meeting information and notes, see [gRPC Community Meeting Working
Doc][grpcmeetings] ([bit.ly/grpcmeetings][grpcmeetings]).

## Contribute

Interested in contributing to gRPC code or documentation? To learn how, see
[Contributing]({{< relref "contribute" >}}) and
[grpc-community/CONTRIBUTING.md][].

[grpc-community/CONTRIBUTING.md]: https://github.com/grpc/grpc-community/blob/master/CONTRIBUTING.md

### gRPC Ecosystem

The [gRPC Ecosystem][] GitHub organization hosts selected gRPC community
projects.

Know of a gRPC project that's a good candidate for the ecosystem? Read the
organization's [How to contribute][grpc-ecosystem-how-to], and submit a [gRPC
Ecosystem Project Request][].

</div>

{{< page/toc placement="sidebar" >}}

</div>

{{< page/page-meta-links >}}

</div>

[@grpcio]: https://twitter.com/grpcio
[gRFCs]: https://github.com/grpc/proposal
[gRPC Ecosystem Project Request]: https://docs.google.com/a/google.com/forms/d/119zb79XRovQYafE9XKjz9sstwynCWcMpoJwHgZJvK74
[gRPC Ecosystem]: https://github.com/grpc-ecosystem
[grpc-ecosystem-how-to]: https://github.com/grpc/grpc-community/blob/master/grpc_ecosystem.md
[grpc-io]: https://groups.google.com/forum/#!forum/grpc-io
[grpc-tag]: https://stackoverflow.com/questions/tagged/grpc
[gRPCio]: https://www.meetup.com/gRPCio/
[grpcmeetings]: https://bit.ly/grpcmeetings
[language]: {{< relref "languages" >}}
[mailing list]: https://groups.google.com/forum/#!forum/grpc-io
[platform]: {{< relref "platforms" >}}
[protoc-tag]: https://stackoverflow.com/questions/tagged/protoc
