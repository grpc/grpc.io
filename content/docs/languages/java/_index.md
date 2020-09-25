---
title: &lang Java
language: *lang
api_path: grpc-java/javadoc
src_repo: github.com/grpc/grpc-java
src_repo_content: github.com/grpc/grpc-java/blob/master
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
- [Android example](https://{{< param src_repo_content >}}/examples/android/)
- [Additional docs](https://{{< param src_repo_content >}}/documentation/)

</div><div class="column resource-list">

#### Reference

- [API](api/)
- [Generated code](generated-code/)

</div><div class="column resource-list">

#### Other

- [grpc-{{< plower language >}} repo](https://{{< param src_repo >}})
- [Download](https://{{< param src_repo >}}#download)
</div>
</div>

---

#### Developer stories and talks

- **gRPC and Java Diamond Dependency Conflicts**
  <a href="https://youtu.be/4M5fC9XrtKs"><i class="fab fa-youtube"></i></a>
  <a href="https://static.sched.com/hosted_files/grpcconf20/7a/gRPC%20and%20Java%20Diamond%20Dependency%20Conflicts.pdf"><i class="far fa-file"></i></a><br>
  A [gRPC Conf 2020 presentation](https://sched.co/cRfT)
  by Tomo Suzuki, Google.
- **Service Interoperability With gRPC: gRPC in Action**
  <a href="https://youtu.be/MLS7TFHrn_c"><i class="fab fa-youtube"></i></a>
  <a href="https://static.sched.com/hosted_files/grpcconf20/d3/Service%20Interoperability%20with%20gRPC.pdf"><i class="far fa-file"></i></a><br>
  A [gRPC Conf 2020 presentation](https://sched.co/cRfl)
  by Varun Gupta & Tuhin Kanti Sharma, Salesforce.
