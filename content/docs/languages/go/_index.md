---
title: &lang Go
language: *lang
api_path: https://pkg.go.dev/google.golang.org/grpc
src_repo: github.com/grpc/grpc-go
src_repo_content: github.com/grpc/grpc-go/blob/master
---

<style>
  .card {
    min-height: 100%;
  }
  .resource-list ul {
    list-style: none;
    margin: 0;
    padding: 0;
  }
</style>

<div class="columns">
  <div class="column">
    <div class="card" href="#">
      <div class="card-content">
        <h4>
          <a class="" href="quickstart/">Quick start</a>
        </h4>
        <p>
          Run your first
          {{< param language >}}
          gRPC app in minutes!
        </p>
      </div>
    </div>
  </div>

  <div class="column">
    <div class="card">
      <div class="card-content">
        <h4>
          <a class="" href="basics/">Basics tutorial</a>
        </h4>
        <p>
          Learn about
          {{< param language >}}
          gRPC basics.
        </p>
      </div>
    </div>
  </div>
</div>

---

<div class="columns">
<div class="column resource-list">

#### Learn more

- [Examples](https://{{< param src_repo_content >}}/examples/)
- [Additional docs](https://{{< param src_repo_content >}}/Documentation/)
- [Installation](https://{{< param src_repo >}}#installation)
- [FAQ](https://{{< param src_repo >}}#faq)

</div><div class="column resource-list">

#### Reference

- [API](api/)
- [Generated code](generated-code/)

</div><div class="column resource-list">

#### Other

- [Performance benchmark][]
- [grpc-{{< plower language >}} repo](https://{{< param src_repo >}})
</div>
</div>

---

#### Developer stories and talks

- **Talking to Go gRPC Services Via HTTP/1**
  <a href="https://youtu.be/Vbw8h0RCn2E"><i class="fab fa-youtube"></i></a>
  <a href="https://static.sched.com/hosted_files/grpcconf20/c9/TalkingToGoGRPCviaHTTP1-gRPCConf2020-MalteIsberner.pdf"><i class="far fa-file"></i></a><br>
  A [gRPC Conf 2020 presentation](https://sched.co/cRfW)
  by Malte Isberner, StackRox.

[Performance benchmark]: https://performance-dot-grpc-testing.appspot.com/explore?dashboard=5652536396611584&widget=490377658&container=1286539696
