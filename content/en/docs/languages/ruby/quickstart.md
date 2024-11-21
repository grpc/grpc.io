---
title: Quick start
description: This guide gets you started with gRPC in Ruby with a simple working example.
weight: 10
---

### Prerequisites

- Ruby version 2 or higher

#### gRPC

To install gRPC, run the following command:

```sh
gem install grpc
```

#### gRPC tools

Ruby's gRPC tools include the protocol buffer compiler `protoc` and the special
plugin for generating server and client code from the `.proto` service
definitions. For the first part of our quick-start example, we've already
generated the server and client stubs from
[helloworld.proto](https://github.com/grpc/grpc/tree/{{< param grpc_vers.core >}}/examples/protos/helloworld.proto),
but you'll need the tools for the rest of our quick start, as well as later
tutorials and your own projects.

To install gRPC tools, run the following command:

```sh
gem install grpc-tools
```

### Download the example

You'll need a local copy of the example code to work through this quick start.
Download the example code from our GitHub repository (the following command
clones the entire repository, but you just need the examples for this quick start
and other tutorials):

```sh
# Clone the repository to get the example code:
git clone -b {{< param grpc_vers.core >}} --depth 1 --shallow-submodules https://github.com/grpc/grpc
# Navigate to the "hello, world" Ruby example:
cd grpc/examples/ruby
```

### Run a gRPC application

From the `examples/ruby` directory:

 1. Run the server:

    ```sh
    ruby greeter_server.rb
    ```

 2. From another terminal, run the client:

    ```sh
    ruby greeter_client.rb
    ```

Congratulations! You've just run a client-server application with gRPC.

### Update the gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [Basics tutorial](../basics/). For now all you need
to know is that both the server and the client "stub" have a `SayHello` RPC
method that takes a `HelloRequest` parameter from the client and returns a
`HelloResponse` from the server, and that this method is defined like this:


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

Remember to save the file!

### Generate gRPC code

Next we need to update the gRPC code used by our application to use the new
service definition. From the `examples/ruby/` directory:

```sh
grpc_tools_ruby_protoc -I ../protos --ruby_out=lib --grpc_out=lib ../protos/helloworld.proto
```

This regenerates `lib/helloworld_services_pb.rb`, which contains our generated
client and server classes.

#### Update the server

In the same directory, open `greeter_server.rb`. Implement the new method like this

```rb
class GreeterServer < Helloworld::Greeter::Service

  def say_hello(hello_req, _unused_call)
    Helloworld::HelloReply.new(message: "Hello #{hello_req.name}")
  end

  def say_hello_again(hello_req, _unused_call)
    Helloworld::HelloReply.new(message: "Hello again, #{hello_req.name}")
  end
end
```

#### Update the client

In the same directory, open `greeter_client.rb`. Call the new method like this:

```rb
def main
  stub = Helloworld::Greeter::Stub.new('localhost:50051', :this_channel_is_insecure)
  user = ARGV.size > 0 ?  ARGV[0] : 'world'
  message = stub.say_hello(Helloworld::HelloRequest.new(name: user)).message
  p "Greeting: #{message}"
  message = stub.say_hello_again(Helloworld::HelloRequest.new(name: user)).message
  p "Greeting: #{message}"
end
```

#### Run!

Just like we did before, from the `examples/ruby` directory:

 1. Run the server:

    ```sh
    ruby greeter_server.rb
    ```

 2. From another terminal, run the client:

    ```sh
    ruby greeter_client.rb
    ```

### What's next

- Learn how gRPC works in [Introduction to gRPC](/docs/what-is-grpc/introduction/)
  and [Core concepts](/docs/what-is-grpc/core-concepts/).
- Work through the [Basics tutorial](../basics/).
- Explore the [API reference](../api).
