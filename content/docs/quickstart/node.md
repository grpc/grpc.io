---
title: Node Quick Start
layout: quickstart
short: Node
---
<p class="lead">This guide gets you started with gRPC in Node with a simple
working example.</p>

<div id="toc"></div>

### Before you begin

#### Prerequisites

 * `node`: version 4.0.0 or higher

### Download the example

You'll need a local copy of the example code to work through this quickstart.
Download the example code from our GitHub repository (the following command
clones the entire repository, but you just need the examples for this quickstart
and other tutorials):

```sh
$ # Clone the repository to get the example code
$ git clone -b {{< param grpc_release_tag >}} https://github.com/grpc/grpc
$ # Navigate to the dynamic codegen "hello, world" Node example:
$ cd grpc/examples/node/dynamic_codegen
$ # Install the example's dependencies
$ npm install
```

### Run a gRPC application

From the `examples/node/dynamic_codegen` directory:

 1. Run the server

    ```sh
    $ node greeter_server.js
    ```

 2. In another terminal, run the client

    ```sh
    $ node greeter_client.js
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [gRPC Basics: Node](/docs/tutorials/basic/node/). For now all you need
to know is that both the server and the client "stub" have a `SayHello` RPC
method that takes a `HelloRequest` parameter from the client and returns a
`HelloReply` from the server, and that this method is defined like this:


```proto
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

Let's update this so that the `Greeter` service has two methods. Edit
`examples/protos/helloworld.proto` and update it with a new `SayHelloAgain`
method, with the same request and response types:

```proto
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  // Sends another greeting
  rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

(Don't forget to save the file!)

### Update and run the application

We now have a new service definition, but we still need to implement and call
the new method in the human-written parts of our example application.

#### Update the server

In the same directory, open `greeter_server.js`. Implement the new method like
this:

```js
function sayHello(call, callback) {
  callback(null, {message: 'Hello ' + call.request.name});
}

function sayHelloAgain(call, callback) {
  callback(null, {message: 'Hello again, ' + call.request.name});
}

function main() {
  var server = new grpc.Server();
  server.addProtoService(hello_proto.Greeter.service,
                         {sayHello: sayHello, sayHelloAgain: sayHelloAgain});
  server.bind('0.0.0.0:50051', grpc.ServerCredentials.createInsecure());
  server.start();
}
...
```

#### Update the client

In the same directory, open `greeter_client.js`. Call the new method like this:

```js
function main() {
  var client = new hello_proto.Greeter('localhost:50051',
                                       grpc.credentials.createInsecure());
  client.sayHello({name: 'you'}, function(err, response) {
    console.log('Greeting:', response.message);
  });
  client.sayHelloAgain({name: 'you'}, function(err, response) {
    console.log('Greeting:', response.message);
  });
}
```

#### Run!

Just like we did before, from the `examples/node/dynamic_codegen` directory:

 1. Run the server

    ```sh
    $ node greeter_server.js
    ```

 2. In another terminal, run the client

    ```sh
    $ node greeter_client.js
    ```

### What's next

 - Read a full explanation of how gRPC works in [What is gRPC?](/docs/guides/)
   and [gRPC Concepts](/docs/guides/concepts/)
 - Work through a more detailed tutorial in [gRPC Basics: Node](/docs/tutorials/basic/node/)
 - Explore the gRPC Node core API in its [reference
   documentation](/grpc/node/)
 - We do have more than one grpc implementation for nodejs. [Learn about the pros and cons of each here](https://github.com/grpc/grpc-node/blob/master/PACKAGE-COMPARISON.md).
