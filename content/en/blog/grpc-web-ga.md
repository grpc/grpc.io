---
title: gRPC-Web is Generally Available
date: 2018-10-23
spelling: cSpell:ignore Cheung Kailash Sethuraman todos
authors:
- name: Luc Perkins
  position: Developer advocate, [Cloud Native Computing Foundation](https://cncf.io)
- name: Stanley Cheung
  position: Google
- name: Kailash Sethuraman
  position: Google
---

We are excited to announce the GA release of
[gRPC-Web](https://www.npmjs.com/package/grpc-web), a JavaScript client library
that enables web apps to communicate directly with gRPC backend services,
without requiring an HTTP server to act as an intermediary. "GA" means that
gRPC-Web is now Generally Available and stable and qualified for production use.

<!--more-->

With gRPC-Web, you can now easily build truly end-to-end gRPC application
architectures by defining your client *and* server-side data types and service
interfaces with Protocol Buffers. This has been a hotly requested feature for a
while, and we are finally happy to say that it is now ready for production use.
In addition, being able to access gRPC services opens up new an exciting
possibilities for [web based
tooling](https://github.com/grpc/grpc-experiments/tree/master/gdebug) around gRPC.

## The Basics

gRPC-Web, just like gRPC, lets you define the service "contract" between client
(web) and backend gRPC services using Protocol Buffers. The client can then be
auto generated. To do this, you have a choice between the [Closure](https://developers.google.com/closure/compiler/) compiler
or the more widely used [CommonJS](https://requirejs.org/docs/commonjs.html).
This development process removes the need to manage concerns such as creating
custom JSON serialization and deserialization logic, wrangling HTTP status codes
(which can vary across REST APIs), managing content type negotiation etc.

From a broader architectural perspective, gRPC-Web enables end-to-end gRPC. The diagram below illustrates this:

![](/img/grpc-web-arch.png)
<p style="text-align: center"> Figure 1. gRPC with gRPC-Web (left) and gRPC with REST (right)</p>

In the gRPC-Web universe on the left, a client application speaks Protocol Buffers to a gRPC backend server that speaks Protocol Buffers to other gRPC backend services. In the REST universe on the right, the web app speaks HTTP to a backend REST API server that then speaks Protocol Buffers to backend services.

## Advantages of using gRPC-Web

gRPC-Web will offer an ever-broader feature set over time, but here’s what’s in 1.0 today:

* **End-to-end gRPC** — Enables you to craft your entire RPC pipeline using Protocol Buffers. Imagine a scenario in which a client request goes to an HTTP server, which then interacts with 5 backend gRPC services. There’s a good chance that you’ll spend as much time building the HTTP interaction layer as you will building the entire rest of the pipeline.
* **Tighter coordination between frontend and backend teams**  — With the entire RPC pipeline defined using Protocol Buffers, you no longer need to have your “microservices teams” alongside your “client team.” The client-backend interaction is just one more gRPC layer amongst others.
* **Easily generate client libraries**  — With gRPC-Web, the server that interacts with the “outside” world, i.e. the membrane connecting your backend stack to the internet, is now a gRPC server instead of an HTTP server, that means that all of your service’s client libraries can be gRPC libraries. Need client libraries for Ruby, Python, Java, and 4 other languages? You no longer need to write HTTP clients for all of them.

## A gRPC-Web example

The previous section illustrated some of the high-level advantages of gRPC-Web for large-scale applications. Now let’s get closer to the metal with an example: a simple TODO app. In gRPC-Web you can start with a simple `todos.proto` definition like this:

```proto
syntax = "proto3";

package todos;

message Todo {
  string content = 1;
  bool finished = 2;
}

message GetTodoRequest {
  int32 id = 1;
}

service TodoService {
  rpc GetTodoById (GetTodoRequest) returns (Todo);
}
```

CommonJS client-side code can be generated from this `.proto` definition with the following command:

```sh
protoc echo.proto \
  --js_out=import_style=commonjs:./output \
  --grpc-web_out=import_style=commonjs:./output
```

Now, fetching a list of TODOs from a backend gRPC service is as simple as:

```js
const {GetTodoRequest} = require('./todos_pb.js');
const {TodoServiceClient} = require('./todos_grpc_web_pb.js');

const todoService = new proto.todos.TodoServiceClient('http://localhost:8080');
const todoId = 1234;

var getTodoRequest = new proto.todos.GetTodoRequest();
getTodoRequest.setId(todoId);

var metadata = {};
var getTodo = todoService.getTodoById(getTodoRequest, metadata, (err, response) => {
  if (err) {
    console.log(err);
  } else {
    const todo = response.todo();
    if (todo == null) {
      console.log(`A TODO with the ID ${todoId} wasn't found`);
    } else {
      console.log(`Fetched TODO with ID ${todoId}: ${todo.content()}`);
    }
  }
});
```

Once you declare the data types and a service interface, gRPC-Web abstracts away all the boilerplate, leaving you with a clean and human-friendly API (essentially the same API as the current [Node.js](/docs/languages/node/) for gRPC API, just transferred to the client).

On the backend, the gRPC server can be written in any language that supports gRPC, such as Go, Java, C++, Ruby, Node.js, and many others. The last piece of the puzzle is the service proxy. From the get-go, gRPC-Web will support [Envoy](https://envoyproxy.io) as the default service proxy, which has a built-in [envoy.grpc_web filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_filters/grpc_web_filter#config-http-filters-grpc-web) that you can apply with just a few lines of configuration.

## Next Steps

Going GA means that the core building blocks are firmly in place and ready for usage in production web applications. But there’s still much more to come for gRPC-Web. Check out the [official road map](https://github.com/grpc/grpc-web/blob/master/doc/roadmap.md) to see what the core team envisions for the near future.

If you’re interested in contributing to gRPC-Web, there are a few things we would love community help with:

* **Front-end framework integration** — Commonly used front-end frameworks like [React](https://reactjs.org), [Vue](https://vuejs.org) and [Angular](https://angular.io) don't yet offer official support for gRPC-Web. But we would love to see these frameworks support it since the integration between these frontend frameworks and gRPC-Web can be a vehicle to deliver user-perceivable performance benefits to applications. If you are interested in building out support for these frontend frameworks, let us know on the [gRPC.io mailing list](https://groups.google.com/g/grpc-io), [filing a feature request on github](https://github.com/grpc/grpc-web/issues) or via the feature survey form below.

* **Language-specific proxy support** — As of the GA release, [Envoy](https://envoyproxy.io) is the default proxy for gRPC-Web, offering support via a special module. NGINX is also [supported](https://github.com/grpc/grpc-web/tree/master/net/grpc/gateway/nginx). But we’d also love to see development of in-process proxies for specific languages since they obviate the need for special proxies—such as Envoy and nginx—and would make using gRPC-Web even easier.

We’d also love to get feature requests from the community. Currently the best way to make feature requests is to fill out the [gRPC-Web road map features survey](https://docs.google.com/forms/d/1NjWpyRviohn5jaPntosBHXRXZYkh_Ffi4GxJZFibylM/viewform?edit_requested=true). When filling up the form, list features you’d like to see and also let us know if you’d like to contribute to the development of those features in the **I’d like to contribute to** section. The gRPC-Web engineers will be sure to take that information to heart over the course of the project’s development.

Most importantly, we want to thank all the Alpha and Beta users who have given us feedback, bug reports and pull requests contributions over the course of the past year. We would certainly hope to maintain this momentum and make sure this project brings tangible benefits to the developer community.
