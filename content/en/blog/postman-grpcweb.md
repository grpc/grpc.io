---
title: Can gRPC replace REST and WebSockets for Web Application Communication?
date: 2023-12-04
author:
  name: Ian Douglas
  position: Sr Developer Advocate, Postman
  link: https://linkedin.com/in/iandouglas736
---

{{% alert color="info" %}}
Welcome to this guest blog entry from our friends at
[Postman](https://www.postman.com/)!
{{% /alert %}}

In the rapidly evolving landscape of web development, efficiency and
performance often stand at the forefront of adoption of new technologies.
The work being done with the [gRPC-Web](https://github.com/grpc/grpc-web)
library marks a pivotal shift in how developers can utilize the speed and
power of [gRPC](https://grpc.io/) into client-server communication in web
applications by replacing REST and some aspects of WebSockets. Let’s look at a
comparative analysis with traditional RESTful calls and WebSocket connections,
and offer practical code samples with gRPC-Web to draw comparisons in each approach.


## Understanding gRPC-Web and Its Place in Modern Web Development

The genesis of gRPC-Web lies in the quest for more responsive, low-latency web
applications. It extends the capabilities of gRPC – a high-performance,
open-source universal RPC framework – to the browser, enabling direct
communication with gRPC services normally designated to server-to-server
communication. gRPC is structured around a serialization format called [Protocol
Buffers (Protobuf)](https://protobuf.dev/), which facilitates smaller payloads
and well-defined interface descriptions that streamline the development process.

Before diving into the technicalities, let’s examine the potential shift that
gRPC-Web represents. Unlike the native gRPC protocol, which requires HTTP/2,
gRPC-Web relaxes this requirement, allowing it to support any HTTP/* protocols
available in a browser environment. In a WebSocket scenario, a persistent
connection is maintained for full-duplex communication, but WebSockets can
introduce complexity in managing various connection states. gRPC-Web offers a
compelling alternative with its server streaming capabilities, leading to a
more efficient real-time data flow. At present, gRPC-Web does not support
client-side streaming due to browser constraints.


## The Mechanics of gRPC-Web: How It Works

To integrate gRPC-Web into your web application, a specific architecture must be
adopted. At the heart of this architecture lies the [Envoy
proxy](https://www.envoyproxy.io/), which serves as a bridge between the web
application and the gRPC server (this is necessary to allow abstraction of
network protocols). Envoy translates the gRPC-Web calls into gRPC calls,
handling the HTTP/1.1 to HTTP/2 conversion, allowing browsers to enjoy the
benefits of gRPC.

Let's break down the steps involved in this communication model:
  1. The browser initiates a gRPC-Web client call.
  2. The Envoy proxy receives the call, which includes the Protobuf-defined
     request.
  3. Envoy then translates this into an HTTP/2 gRPC call and forwards it to the
     gRPC server.
  4. The gRPC server processes the request and returns the response to Envoy.
  5. Envoy converts the gRPC response back into gRPC-Web format and sends it to
     the client.

Using this proxy system, gRPC-Web facilitates a robust client-server interaction
that is performant, and offers data clarity and precision thanks to the strong
data typing of Protobuf.


## The Theory of Transitioning from REST to gRPC-Web

For developers accustomed to REST, the leap to gRPC-Web may seem challenging.
The transition can be smooth with a proper understanding of the involved
components and a step-by-step approach.

Consider a typical RESTful fetch call:

```js
fetch('https://api.example.com/data', {
    method: 'GET',
    headers: {
        'Accept': 'application/json',
    },
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));
```

The above code retrieves JSON data from a RESTful API service. Notice the use of
the fetch API, HTTP method, and content type headers. The response is processed
as a JSON object, and error handling is baked into the promise chain. What is
not indicated in this code is the data validation that is needed to ensure the
data you received in the payload matches an expected schema, and that the data
received in the schema is properly set in the data type you require, and the
user experience of handling erroneous data.

Let's reimagine this with gRPC-Web:

```js
const { ExampleRequest, ExampleResponse } = require('./generated/example_pb.js');
const { ExampleServiceClient } = require('./generated/example_grpc_web_pb.js');

const client = new ExampleServiceClient('https://api.example.com');

const request = new ExampleRequest();

client.getExampleData(request, {}, (err, response) => {
    if (err) {
        console.error('Error:', err);
    } else {
        console.log(response.toObject());
    }
});
```

In this gRPC-Web example, we begin by importing the necessary Protobuf
definitions and client stub. A client instance is created, specifying the
service URL. We construct a request object, and the getExampleData method is
called on the client, passing the request and a callback function for handling
the response or error.

Notice the stark difference in approach: gRPC-Web calls are strongly-typed, and
serialization/deserialization is handled by the library, not manually by the
developer. This type safety and automation can drastically reduce the potential
for human error and streamline the development process. If you receive an
object, it has already been fully validated.


## Advantages of gRPC-Web Over REST

While REST has been the cornerstone of web APIs for years, its simplicity can
sometimes be a limitation when it comes to complex web applications. While
gRPC-Web can [work with any HTTP/*
protocols](https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-WEB.md#protocol-differences-vs-grpc-over-http2)
supported in the browser, gRPC-Web leverages many HTTP/2 features, bringing a
host of improvements. Here are some advantages of HTTP/2 and gRPC-Web:

  * **It works with existing services:** There’s nothing new to build other than the
    Envoy proxy, so implementing gRPC-Web will allow you to access any existing
    gRPC service. This can be an advantage for applications, including mobile
    apps, utilizing JavaScript libraries. 
  * **Type Safety:** With gRPC-Web, both requests and responses are strongly typed
    based on the Protobuf definitions. This contract between the client and
    server is explicit, reducing the likelihood of miscommunication and bugs.
  * **Efficient Serialization:** Protobuf, the serialization format used by gRPC, is
    more efficient than JSON or XML, leading to quicker serialization and
    smaller message sizes. This can be particularly beneficial for performance
    and can lead to cost savings in terms of bandwidth. HTTP/1.1 allows data to
    be sent in text mode or binary mode, but not both. HTTP/2 is binary-only and
    encoding/decoding binary into text is less error-prone than
    encoding/decoding a binary file into text to send a mixed payload over REST.
  * **Clear API Contracts:** Using Protobuf for service definition creates a clear,
    language-agnostic API contract. This can be used to generate client and
    server code in multiple languages, providing a seamless experience for
    developers.


## Setting Up a gRPC-Web Environment

Getting started with gRPC-Web will require defining services and message
payloads using Protobuf, setting up the gRPC backend service (or [a mock server
for the time being](https://blog.postman.com/postman-mocking-magic-for-grpcs/)),
and configuring an Envoy proxy to translate between gRPC-Web and gRPC.

First, you define your service in a .proto file:

```proto
syntax = "proto3";

package example;

service ExampleService {
  rpc GetExampleData(ExampleRequest) returns (ExampleResponse);
}

message ExampleRequest {
  string query = 1;
}

message ExampleResponse {
  repeated string data = 1;
}
```

This `.proto` file defines a simple service with a single RPC method,
`GetExampleData`, along with the request and response message formats. Since the
operation sends a single `ExampleRequest` message in the request, and expects to
receive a single `ExampleResponse` message in the response, this unary RPC call
mimics a RESTful request.

Next, generate the client stub code for your service using the protoc
command-line tool with the appropriate gRPC-Web plugin. ([Here is an
example](https://blog.postman.com/postman-mocking-magic-for-grpcs/) from the
gRPC-Web quickstart documentation). This process will create the JavaScript
client files you'll need to make gRPC-Web calls from the browser.

After your gRPC server is implemented in the language of your choice, you'll
configure an Envoy proxy. [Here is another
example](https://blog.postman.com/postman-mocking-magic-for-grpcs/) from the
gRPC-Web quickstart documentation.

Here is some YAML syntax of an Envoy configuration which enables gRPC-Web as
part of the larger configuration linked above.

```yaml
http_filters:
- name: envoy.filters.http.grpc_web
- name: envoy.filters.http.router
```

With these elements in place, you can start making gRPC-Web calls from your web
application.


## Defining Service Methods with Protobuf

When defining your service methods, Protobuf acts as the single source of truth
by defining the message structure for requests and responses. This strict schema
allows for automatic client and server code generation in multiple languages.
For JavaScript in particular, this code generation streamlines the call process
for the browser client.

Using the example .proto file above, the generated JavaScript client code would
use these definitions to ensure that only the correct data types are sent and
received. This process handles much of the manual data validation and parsing
that can be error-prone with RESTful services.


## Replacing a Typical WebSocket Connection with gRPC-Web

WebSockets provide a full-duplex communication channel over a single long-lived
connection. In scenarios where gRPC-Web cannot fully replace WebSockets due to
its [lack of client streaming
capabilities](https://github.com/grpc/grpc-web/blob/master/doc/streaming-roadmap.md#client-streaming-and-half-duplex-streaming),
it can still be used for efficient server-to-client streaming.

Here's a typical WebSocket implementation example:

```js
const socket = new WebSocket('ws://example.com/data');

socket.onmessage = function(event) {
  const receivedData = JSON.parse(event.data);
  console.log(receivedData);
};

socket.onerror = function(error) {
  console.error('WebSocket Error:', error);
};
```

The WebSocket API is straightforward, but managing the state and lifecycle of
the connection can become complex.

Now, let's explore how server-side streaming would look with gRPC-Web:

```js
const { Empty } = require('./generated/common_pb.js');
const { DataServiceClient } = require('./generated/data_grpc_web_pb.js');

const client = new DataServiceClient('https://api.example.com');

const request = new Empty();

const stream = client.dataStream(request, {});

stream.on('data', (response) => {
  console.log(response.toObject());
});

stream.on('error', (err) => {
  console.error('Stream Error:', err);
});

stream.on('end', () => {
  console.log('Stream ended.');
});
```

While there is more code involved to replace WebSockets with gRPC-Web, you can
set up a server-side streaming call where the server can continuously send
messages to the client. The client uses event listeners to handle incoming
messages, errors, and the end of the stream. It's a different paradigm than
WebSockets but one that can be more efficient and easier to manage in the
context of supported use cases.

Many chat applications over WebSockets utilize single client sends and server
streamed events, which gRPC-Web can replace. Even in scenarios where a
multiplayer game was developed, an RPC call of “MoveCharacters” could take a
single message from the browser from where you move your character, and stream
back all of the movements of other players or computer-controlled characters.


## Is It Time to Replace REST and WebSockets?

This article has begun to scratch the surface of replacing REST and WebSockets
with gRPC-Web, focusing on the reasons for doing so and how to get started with
practical code samples. More work would be needed to fully incorporate error
handling, and to show performance benchmarking, which are beyond the scope of
this document.

Many technical aspects of gRPC and gRPC-Web, using Envoy, can replace REST and
WebSockets in modern web application development. While there are [few
public-facing gRPC APIs](https://grpc.io/showcase/), it’s a matter of time
before we see more companies adopting the performant nature of HTTP/2 and HTTP/3
based APIs, and consider alternative emerging technologies for web applications.


## gRPC Support in Postman

If you work with APIs, you probably use Postman. Did you know that [Postman
supports gRPC](https://blog.postman.com/postman-now-supports-grpc/)? Our [VS
Code extension supports gRPC
requests](https://blog.postman.com/introducing-the-postman-vs-code-extension/),
too, while you’re building your application. We had a great time attending gRPC
Conf this year and meeting with the community. Keep an eye on our blog for
[upcoming updates and articles about gRPC](https://blog.postman.com/?s=grpc). If
you’d like a little history on gRPC, Protobuf, and how they’re used within
Postman, you can also check out our [Postman Academy
course](https://academy.postman.com/grpc-and-postman).

_Technical reviews by [Kevin Swiber](https://twitter.com/kevinswiber) (Postman),
[Eryu Xia](https://www.linkedin.com/in/eryux/) (Google)_
