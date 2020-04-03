---
title: "Not just for HTTP anymore: gRPC comes to Cloud Run"
date: 2020-03-17
authors:
- name: Richard Belleville
  link: https://github.com/gnossen
- name: Wenlei He
  link: https://github.com/wlhee
---

[Cloud Run](https://cloud.google.com/run) is a managed serverless compute offering from Google Cloud that lets you run stateless server containers in a fully managed environment, without the hassle of managing the underlying infrastructure. Since its release, Cloud Run has enabled many of our customers to focus on their business logic, while leaving the provisioning, configuring, and scaling to us.

<!--more-->

Most applications that run inside Cloud Run use HTTP JSON REST to serve requests, but that’s not the only protocol it supports; in September, it also started to support unary gRPC services.

gRPC is a high performance RPC framework developed by Google and used extensively for traditional workloads and at the edge by companies like Netflix, Cisco, Square, and others. While gRPC offers advantages over traditional HTTP, like strong interface definitions and code generation, setting up the infrastructure to run a gRPC server in production can be a real chore. Cloud Run takes the toil out of this process.


With gRPC, you start with a strong API contract in the form of a [protocol buffer file](https://developers.google.com/protocol-buffers):

```protobuf
syntax = "proto3";

enum Operation {
  ADD = 0;
  SUBTRACT = 1;
}

message BinaryOperation {
  float first_operand = 1;
  float second_operand = 2;
  Operation operation = 3;
};

message CalculationResult {
  float result = 1;
};

service Calculator {
  rpc Calculate (BinaryOperation) returns (CalculationResult);
};
```

This interface definition ensures that your clients and servers speak the same language even as you extend the capabilities of your service. You then generate code from this definition in your desired language and provide an implementation for it:

```python
class Calculator(calculator_pb2_grpc.CalculatorServicer):

  def Calculate(self,
                request: calculator_pb2.BinaryOperation,
                context: grpc.ServicerContext) -> None:
      logging.info("Received request: %s", request)
      if request.operation == calculator_pb2.ADD:
          result = request.first_operand + request.second_operand
      else:
          result = request.first_operand - request.second_operand
      return calculator_pb2.CalculationResult(result=result)
```
Cloud Run provides everything else you need to get your code serving traffic. You just need to put together a simple Dockerfile and run a few commands:

```bash
docker build -t gcr.io/my-project/my-grpc-app:latest .
docker push gcr.io/my-project/my-grpc-app:latest
gcloud run deploy --image gcr.io/my-project/my-grpc-app:latest --platform managed
```

We've put together additional examples in [several languages](https://github.com/grpc-ecosystem/grpc-cloud-run-example) to help you get started running a simple gRPC service in fully managed Cloud Run. We're excited to see the gRPC services you'll deploy!

Support for gRPC in Cloud Run is evolving. For example, we’re still working on support for streaming. For use cases where you want to send data incrementally from client to server, you're currently better off chaining together a series of unary RPCs or REST requests. Additionally, Cloud Run’s gRPC data path currently works best for small requests. As a rule of thumb, you should keep your requests below 32MB in size. We plan to improve this over time, but for now you can learn more about gRPC on Cloud Run with [this tutorial.](https://github.com/grpc-ecosystem/grpc-cloud-run-example)


*Google Cloud Blog [cross-post](https://cloud.google.com/blog/products/compute/serve-cloud-run-requests-with-grpc-not-just-http)*
