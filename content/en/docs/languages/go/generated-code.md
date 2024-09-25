---
title: Generated-code reference
linkTitle: Generated code
weight: 95
---

This page describes the code generated with the [grpc plugin](https://pkg.go.dev/google.golang.org/grpc/cmd/protoc-gen-go-grpc), `protoc-gen-go-grpc`,
when compiling `.proto` files with `protoc`.

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

`Foo(context.Context, *MsgA) (*MsgB, error)`

In this context, `MsgA` is the protobuf message sent from the client, and `MsgB` is the protobuf message sent back from the server.

### Server-streaming methods

These methods have the following signature on the generated service interface:
`Foo(*MsgA, grpc.ServerStreamingServer[*MsgB]) error`

In this context, `MsgA` is the single request from the client, and , and `grpc.ServerStreamingServer` represents the  server side of server-to-client stream of response type `MsgB`.

`<ServiceName>_FooServer` has a  `grpc.SreverStreamingServer` interface that takes `MsgB` i.e. the response type as the input:

```go
type <ServiceName>_FooServer = grpc.ServerStreamingServer[*MsgB]
```

The `grpc.SreverStreamingServer` has a `Send(*MsgB)` method and has `ServerStream` embedded in it.
The server-side handler can send a stream of protobuf messages to the client through this parameter’s `Send` method. End-of-stream for the server-to-client stream is caused by the return of the handler method.

### Client-streaming methods

These methods have the following signature on the generated service interface:

`Foo(grpc.ClientStreamingServer[*MsgA, *MsgB]) error`

Where `MsgA` is the message type of the stream sent from client-to-server and `MsgB` is the type of response from server to client.

In this context, `grpc.ClientStreamingServer` can be used both to read the client-to-server message stream and to send the single server response message.

`<ServiceName>_FooServer` has a `grpc.ClientStreamingServer` interface that takes `MsgA` and `MsgB` as input:

```go
type <ServiceName>_FooServer = grpc.ClientStreamingServer[*MsgA, *MsgB]
```

The `grpc.ClientStreamingServer` has two methods `Recv()` and `SendAndClose(*MsgB)` , has an embedded `ServerStream`. The server-side handler can repeatedly call `Recv` on `<ServiceName>_FooServer`  in order to receive the full stream of messages from the client. `Recv` returns `(nil, io.EOF)` once it has reached the end of the stream. The single response message from the server is sent by calling the `SendAndClose` method on this `<ServiceName>_FooServer` parameter. Note that `SendAndClose` must be called once and only once.

### Bidi-streaming methods

These methods have the following signature on the generated service interface:

`Foo(grpc.BidiStreamingServer[*MsgA, *MsgB]) error`

Where `MsgA` is the message type of the stream sent from client-to-server and `MsgB` is the type of stream from server-to-client.

In this context, `grpc.BidiStreamingServer` can be used to access both the client-to-server message stream and the server-to-client message stream. 

`<ServiceName>_FooServer` has a `grpc.BidiStreamingServer` interface as follows:

```go
type <ServiceName>_FooServer = grpc.BidiStreamingServer[*MsgA, *MsgB]
```

The `grpc.BidiStreamingServer` has two methods  `Recv()`  and `Send()` and `ServerStream` embedded in it. The server-side handler can repeatedly call `Recv` on this parameter in order to read the client-to-server message stream. `Recv` returns `(nil, io.EOF)` once it has reached the end of the client-to-server stream. The response server-to-client message stream is sent by repeatedly calling the `Send` method of on this `<ServiceName>_FooServer` parameter. End-of-stream for the server-to-client stream is indicated by the return of the bidi method handler.

## Methods on generated client interfaces

For client side usage, each `service Bar` in the `.proto` file also results in the function: `func BarClient(cc *grpc.ClientConn) BarClient`, which
returns a concrete implementation of the `BarClient` interface (this concrete implementation also lives in the generated `.pb.go` file).

### Unary Methods

These methods have the following signature on the generated client stub:

`(ctx context.Context, in *MsgA, opts ...grpc.CallOption) (*MsgB, error)`

In this context, `MsgA` is the single request from client to server, and `MsgB` contains the response sent back from the server.

### Server-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, in *MsgA, opts ...grpc.CallOption) (grpc.ServerStreamClient[*MsgB], error)`

In this context, `grpc.ServerStreamClient`  represents the client side of server-to-client stream of `MsgB` messages.

The `<ServiceName>_FooClient` has a `grpc.ServerStreamClient` interface:

```go 
type <ServiceName>_FooClient = grpc.ServerStreamingClient[*MsgB] 
```

`grpc.ServerStreamingClient` has an embedded `ClientStream` and a `Recv()` method. The stream begins when the client calls the `Foo` method on the stub. The client can then repeatedly call the `Recv` method on the returned `<ServiceName>_FooClient` stream in order to read the server-to-client response stream. This `Recv` method returns `(nil, io.EOF)` once the server-to-client stream has been completely read through.

### Client-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, opts ...grpc.CallOption) (grpc.ClientStreamingClient[*MsgA, *MsgB], error)`

In this context, `grpc.ClientStreamingClient` represents the client side of client-to-server stream of `MsgA` messages. It can be used both to send the client-to-server message stream and to receive the single server response message.

`<ServiceName>_FooServe`r has a `grpc.ClientStreamingClient` interface that takes `MsgA` and `MsgB` as input:

```go 
type <ServiceName>_FooClient = grpc.ClientStreamingClient[*MsgA, *MsgB]
```

The stream begins when the client calls the `Foo` method on the stub. The `grpc.ClientStreamingClient` interface has an embedded `ClientStream` as well as `Send()` and `CloseAndRecv()` methods. The client can then repeatedly call the `Send` method on the returned `<ServiceName>_FooClient` stream in order to send the client-to-server message stream. The `CloseAndRecv` method on this stream must be called once and only once, in order to both close the client-to-server stream and receive the single response message from the server.

### Bidi-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, opts ...grpc.CallOption) (grpc.BidiStreamingClient[*MsgA, *MsgB], error)`

In this context, `grpc.BidiStreamingClien`t represents both the client-to-server and server-to-client message streams.

`<ServiceName>_FooClient` has a `grpc.BidiStreamingClient` interface:

```go
type <ServiceName>_FooClient = grpc.BidiStreamingClient[*MsgA, *MsgB]
```

The stream begins when the client calls the `Foo` method on the stub. The `grpc.BidiStreamingClient` interface has an embedded `ClientStream` as well as `Send()` and `CloseAndRecv()` methods. The client can then repeatedly call the `Send` method on the returned `<SericeName>_FooClient` stream in order to send the client-to-server message stream. The client can also repeatedly call `Recv` on this stream in order to receive the full server-to-client message stream.

End-of-stream for the server-to-client stream is indicated by a return value of `(nil, io.EOF)` on the Recv method of the stream. End-of-stream for the client-to-server stream can be indicated from the client by calling the `CloseSend` method on the stream.

## Packages and Namespaces

When the `protoc` compiler is invoked with `--go_out=plugins=grpc:`, the `proto package` to Go package translation
works the same as when the `protoc-gen-go` plugin is used without the `grpc` plugin.

So, for example, if `foo.proto` declares itself to be in `package foo`, then the generated `foo.pb.go` file will also be in
the Go `package foo`.
