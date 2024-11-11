---
title: Generated-code reference
linkTitle: Generated code
weight: 95
---
This page describes the code generated when compiling `.proto` files with `protoc`, using the `protoc-gen-go-grpc` [grpc plugin](https://pkg.go.dev/google.golang.org/grpc/cmd/protoc-gen-go-grpc). This latest version of generated code uses generics by default. If you're working with older generated code that doesn't use generics, you can find the relevant documentation [here](/docs/languages/go/generated-code-old).  While we encourage using this latest version with generics, you can temporarily revert to the old behavior by setting the `useGenericStreams` flag to `false`.

You can find out how to define a gRPC service in a `.proto` file in [Service definition](/docs/what-is-grpc/core-concepts/#service-definition).

<p class="note"><strong>Thread-safety</strong>: note that client-side RPC invocations and server-side RPC handlers <i>are thread-safe</i> and are meant
to be run on concurrent goroutines. But also note that for <i>individual streams</i>, incoming and outgoing data is bi-directional but serial;
so e.g. <i>individual streams</i> do not support <i>concurrent reads</i> or <i>concurrent writes</i> (but reads are safely concurrent <i>with</i> writes).
</p>

## Methods on generated server interfaces

On the server side, each `service Bar` in the `.proto` file results in the function:

`func RegisterBarServer(s *grpc.Server, srv BarServer)`

The application can define a concrete implementation of the `BarServer` interface and register it with a `grpc.Server` instance
(before starting the server instance) by using this function.

### Unary methods

These methods have the following signature on the generated service interface:

`Foo(context.Context, *RequestMsg) (*ResponseMsg, error)`

In this context, `RequestMsg` is the protobuf message sent from the client, and `ResponseMsg` is the protobuf message sent back from the server.

### Server-streaming methods

These methods have the following signature on the generated service interface:
`Foo(*RequestMsg, grpc.ServerStreamingServer[*ResponseMsg]) error`

In this context, `RequestMsg` is the single request from the client, and [`grpc.ServerStreamingServer`](https://pkg.go.dev/google.golang.org/grpc#ServerStreamingServer) represents the server side of server-to-client stream of response type `ResponseMsg`.

Refer to [`grpc.ServerStreamingServer`](https://pkg.go.dev/google.golang.org/grpc#ServerStreamingServer) documentation for detailed usage information.

### Client-streaming methods

These methods have the following signature on the generated service interface:

`Foo(grpc.ClientStreamingServer[*RequestMsg, *ResponseMsg]) error`

Where `RequestMsg` is the message type of the stream, sent from client-to-server and `ResponseMsg` is the type of response from server to client.

In this context, [`grpc.ClientStreamingServer`](https://pkg.go.dev/google.golang.org/grpc#ClientStreamingServer) can be used both to read the client-to-server message stream and to send the single server response message.

Refer to [`grpc.ClientStreamingServer`](https://pkg.go.dev/google.golang.org/grpc#ClientStreamingServer) documentation for detailed usage information.

### Bidi-streaming methods

These methods have the following signature on the generated service interface:

`Foo(grpc.BidiStreamingServer[*RequestMsg, *ResponseMsg]) error`

Where `RequestMsg` is the message type of the stream, sent from client-to-server and `ResponseMsg` is the type of stream from server-to-client.

In this context, [`grpc.BidiStreamingServer`](https://pkg.go.dev/google.golang.org/grpc#BidiStreamingServer) can be used to access both the client-to-server message stream and the server-to-client message stream. 

Refer to [`grpc.BidiStreamingServer`](https://pkg.go.dev/google.golang.org/grpc#BidiStreamingServer) documentation for detailed usage information.

## Methods on generated client interfaces

For client side usage, each `service Bar` in the `.proto` file also results in the function: `func BarClient(cc *grpc.ClientConn) BarClient`, which
returns a concrete implementation of the `BarClient` interface (this concrete implementation also lives in the generated `.pb.go` file).

### Unary Methods

These methods have the following signature on the generated client stub:

`(ctx context.Context, in *RequestMsg, opts ...grpc.CallOption) (*ResponseMsg, error)`

In this context, `RequestMsg` is the single request from client to server, and `ResponseMsg` contains the response sent back from the server.

### Server-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, in *RequestMsg, opts ...grpc.CallOption) (grpc.ServerStreamingClient[*ResponseMsg], error)`

In this context, [`grpc.ServerStreamingClient`](https://pkg.go.dev/google.golang.org/grpc#ServerStreamingClient) represents the client side of server-to-client stream of `ResponseMsg` messages.

Refer to [`grpc.ServerStreamingClient`](https://pkg.go.dev/google.golang.org/grpc#ServerStreamingClient) documentation for detailed usage information.


### Client-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, opts ...grpc.CallOption) (grpc.ClientStreamingClient[*RequestMsg, *ResponseMsg], error)`

In this context, [`grpc.ClientStreamingClient`](https://pkg.go.dev/google.golang.org/grpc#ClientStreamingClient) represents the client side of client-to-server stream of `RequestMsg` messages. It can be used both to send the client-to-server message stream and to receive the single server response message.

Refer to [`grpc.ClientStreamingClient`](https://pkg.go.dev/google.golang.org/grpc#ClientStreamingClient) documentation for detailed usage information.


### Bidi-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, opts ...grpc.CallOption) (grpc.BidiStreamingClient[*RequestMsg, *ResponseMsg], error)`

In this context, [`grpc.BidiStreamingClient`](https://pkg.go.dev/google.golang.org/grpc#BidiStreamingClient) represents both the client-to-server and server-to-client message streams.

Refer to [`grpc.BidiStreamingClient`](https://pkg.go.dev/google.golang.org/grpc#BidiStreamingClient) documentation for detailed usage information.


## Packages and Namespaces

When the `protoc` compiler is invoked with `--go_out=plugins=grpc:`, the `proto package` to Go package translation
works the same as when the `protoc-gen-go` plugin is used without the `grpc` plugin.

So, for example, if `foo.proto` declares itself to be in `package foo`, then the generated `foo.pb.go` file will also be in
the Go `package foo`.
