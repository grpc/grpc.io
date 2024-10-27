---
title: Generated-code (legacy non-generic) reference    
LinkTitle: Generated-code (legacy)
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

`Foo(*MsgA, <ServiceName>_FooServer) error`

In this context, `MsgA` is the single request from the client, and the `<ServiceName>_FooServer` parameter represents the server-to-client stream
of `MsgB` messages.

`<ServiceName>_FooServer` has an embedded `grpc.ServerStream` and the following interface:

```go
type <ServiceName>_FooServer interface {
	Send(*MsgB) error
	grpc.ServerStream
}
```

The server-side handler can send a stream of protobuf messages to the client through this parameter's `Send` method. End-of-stream for the server-to-client
stream is caused by the `return` of the handler method.

### Client-streaming methods

These methods have the following signature on the generated service interface:

`Foo(<ServiceName>_FooServer) error`

In this context, `<ServiceName>_FooServer` can be used both to read the client-to-server message stream and to send the single server response message.

`<ServiceName>_FooServer` has an embedded `grpc.ServerStream` and the following interface:

```go
type <ServiceName>_FooServer interface {
	SendAndClose(*MsgA) error
	Recv() (*MsgB, error)
	grpc.ServerStream
}
```

The server-side handler can repeatedly call `Recv` on this parameter in order to receive the full stream of
messages from the client. `Recv` returns `(nil, io.EOF)` once it has reached the end of the stream.
The single response message from the server is sent by calling the `SendAndClose` method on this `<ServiceName>_FooServer` parameter.
Note that `SendAndClose` must be called once and only once.

### Bidi-streaming methods

These methods have the following signature on the generated service interface:

`Foo(<ServiceName>_FooServer) error`

In this context, `<ServiceName>_FooServer` can be used to access both the client-to-server message stream and the server-to-client message stream.
`<ServiceName>_FooServer` has an embedded `grpc.ServerStream` and the following interface:

```go
type <ServiceName>_FooServer interface {
	Send(*MsgA) error
	Recv() (*MsgB, error)
	grpc.ServerStream
}
```

The server-side handler can repeatedly call `Recv` on this parameter in order to read the client-to-server message stream.
`Recv` returns `(nil, io.EOF)` once it has reached the end of the client-to-server stream.
The response server-to-client message stream is sent by repeatedly calling the `Send` method of on this `ServiceName>_FooServer` parameter.
End-of-stream for the server-to-client stream is indicated by the `return` of the bidi method handler.

## Methods on generated client interfaces

For client side usage, each `service Bar` in the `.proto` file also results in the function: `func BarClient(cc *grpc.ClientConn) BarClient`, which
returns a concrete implementation of the `BarClient` interface (this concrete implementation also lives in the generated `.pb.go` file).

### Unary Methods

These methods have the following signature on the generated client stub:

`(ctx context.Context, in *MsgA, opts ...grpc.CallOption) (*MsgB, error)`

In this context, `MsgA` is the single request from client to server, and `MsgB` contains the response sent back from the server.

### Server-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, in *MsgA, opts ...grpc.CallOption) (<ServiceName>_FooClient, error)`

In this context, `<ServiceName>_FooClient` represents the server-to-client `stream` of `MsgB` messages.

This stream has an embedded `grpc.ClientStream` and the following interface:

```go
type <ServiceName>_FooClient interface {
	Recv() (*MsgB, error)
	grpc.ClientStream
}
```

The stream begins when the client calls the `Foo` method on the stub.
The client can then repeatedly call the `Recv` method on the returned `<ServiceName>_FooClient` <i>stream</i> in order to read the server-to-client response stream.
This `Recv` method returns `(nil, io.EOF)` once the server-to-client stream has been completely read through.

### Client-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, opts ...grpc.CallOption) (<ServiceName>_FooClient, error)`

In this context, `<ServiceName>_FooClient` represents the client-to-server `stream` of `MsgA` messages.

`<ServiceName>_FooClient` has an embedded `grpc.ClientStream` and the following interface:

```go
type <ServiceName>_FooClient interface {
	Send(*MsgA) error
	CloseAndRecv() (*MsgB, error)
	grpc.ClientStream
}
```

The stream begins when the client calls the `Foo` method on the stub.
The client can then repeatedly call the `Send` method on the returned `<ServiceName>_FooClient` stream in order to send the client-to-server message stream.
The `CloseAndRecv` method on this stream must be called once and only once, in order to both close the client-to-server stream
and receive the single response message from the server.

### Bidi-Streaming methods

These methods have the following signature on the generated client stub:

`Foo(ctx context.Context, opts ...grpc.CallOption) (<ServiceName>_FooClient, error)`

In this context, `<ServiceName>_FooClient` represents both the client-to-server and server-to-client message streams.

`<ServiceName>_FooClient` has an embedded `grpc.ClientStream` and the following interface:

```go
type <ServiceName>_FooClient interface {
	Send(*MsgA) error
	Recv() (*MsgB, error)
	grpc.ClientStream
}
```

The stream begins when the client calls the `Foo` method on the stub.
The client can then repeatedly call the `Send` method on the returned `<SericeName>_FooClient` stream in order to send the
client-to-server message stream. The client can also repeatedly call `Recv` on this stream in order to
receive the full server-to-client message stream.

End-of-stream for the server-to-client stream is indicated by a return value of `(nil, io.EOF)` on the `Recv` method of the stream.
End-of-stream for the client-to-server stream can be indicated from the client by calling the `CloseSend` method on the stream.

## Packages and Namespaces

When the `protoc` compiler is invoked with `--go_out=plugins=grpc:`, the `proto package` to Go package translation
works the same as when the `protoc-gen-go` plugin is used without the `grpc` plugin.

So, for example, if `foo.proto` declares itself to be in `package foo`, then the generated `foo.pb.go` file will also be in
the Go `package foo`.
