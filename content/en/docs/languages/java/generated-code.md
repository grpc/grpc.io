---
title: Generated-code reference
linkTitle: Generated code
weight: 95
spelling: cSpell:ignore buildscript classpath grpcexample motd srcs xolstice
---

## Packages

For each service defined in a .proto file, the Java code generation produces a
Java class. The class name is the service's name suffixed by `Grpc`. The package
for the generated code is specified in the .proto file using the `java_package`
option.

For example, if `ServiceName` is defined in a .proto file containing the
following:

```protobuf
package grpcexample;

option java_package = "io.grpc.examples";
```

Then the generated class will be `io.grpc.examples.ServiceNameGrpc`.

If `java_package` is not specified, the generated class will use the `package`
as specified in the .proto file. This should be avoided, as proto packages
usually do not begin with a reversed domain name.

## Service Stub

The generated Java code contains an inner abstract class suffixed with
`ImplBase`, such as `ServiceNameImplBase`. This class defines one Java method
for each method in the service definition. It is up to the service implementer
to extend this class and implement the functionality of these methods. Without
being overridden, the methods return an error to the client saying the method is
unimplemented.

The signatures of the stub methods in `ServiceNameImplBase` vary depending on
the type of RPCs it handles. There are four types of gRPC service methods:
unary, server-streaming, client-streaming, and bidirectional-streaming.

### Unary

The service stub signature for a unary RPC method `unaryExample`:

```java
public void unaryExample(
    RequestType request,
    StreamObserver<ResponseType> responseObserver)
```

### Server-streaming

The service stub signature for a server-streaming RPC method
`serverStreamingExample`:

```java
public void serverStreamingExample(
    RequestType request,
    StreamObserver<ResponseType> responseObserver)
```

Notice that the signatures for unary and server-streaming RPCs are the same. A
single `RequestType` is received from the client, and the service implementation
sends its response(s) by invoking `responseObserver.onNext(ResponseType
response)`.

### Client-streaming

The service stub signature for a client-streaming RPC method
`clientStreamingExample`:

```java
public StreamObserver<RequestType> clientStreamingExample(
    StreamObserver<ResponseType> responseObserver)
```

### Bidirectional-streaming

The service stub signature for a bidirectional-streaming RPC method
`bidirectionalStreamingExample`:

```java
public StreamObserver<RequestType> bidirectionalStreamingExample(
    StreamObserver<ResponseType> responseObserver)
```

The signatures for client and bidirectional-streaming RPCs are the same. Since
the client can send multiple messages to the service, the service implementation
is responsible for returning a `StreamObserver<RequestType>` instance. This
`StreamObserver` is invoked whenever additional messages are received from the
client.

## Client Stubs

The generated class also contains stubs for use by gRPC clients to call methods
defined by the service. Each stub wraps a `Channel`, supplied by the user of the
generated code. The stub uses this channel to send RPCs to the service.

gRPC Java generates code for three types of stubs: asynchronous, blocking, and
future. Each type of stub has a corresponding class in the generated code, such
as `ServiceNameStub`, `ServiceNameBlockingStub`, and `ServiceNameFutureStub`.

### Asynchronous Stub

RPCs made via an asynchronous stub operate entirely through callbacks on
`StreamObserver`.

The asynchronous stub contains one Java method for each method from the service
definition.

A new asynchronous stub is instantiated via the `ServiceNameGrpc.newStub(Channel
channel)` static method.

#### Unary

The asynchronous stub signature for a unary RPC method `unaryExample`:

```java
public void unaryExample(
    RequestType request,
    StreamObserver<ResponseType> responseObserver)
```

#### Server-streaming

The asynchronous stub signature for a server-streaming RPC method
`serverStreamingExample`:

```java
public void serverStreamingExample(
    RequestType request,
    StreamObserver<ResponseType> responseObserver)
```

#### Client-streaming

The asynchronous stub signature for a client-streaming RPC method
`clientStreamingExample`:

```java
public StreamObserver<RequestType> clientStreamingExample(
    StreamObserver<ResponseType> responseObserver)
```

#### Bidirectional-streaming

The asynchronous stub signature for a bidirectional-streaming RPC method
`bidirectionalStreamingExample`:

```java
public StreamObserver<RequestType> bidirectionalStreamingExample(
    StreamObserver<ResponseType> responseObserver)
```

### Blocking Stub

RPCs made through a blocking stub, as the name implies, block until the response
from the service is available.

The blocking stub contains one Java method for each unary and server-streaming
method in the service definition. Blocking stubs do not support client-streaming
or bidirectional-streaming RPCs.

A new blocking stub is instantiated via the
`ServiceNameGrpc.newBlockingStub(Channel channel)` static method.

#### Unary

The blocking stub signature for a unary RPC method `unaryExample`:

```java
public ResponseType unaryExample(RequestType request)
```

#### Server-streaming

The blocking stub signature for a server-streaming RPC method
`serverStreamingExample`:

```java
public Iterator<ResponseType> serverStreamingExample(RequestType request)
```

### Future Stub

RPCs made via a future stub wrap the return value of the asynchronous stub in a
`GrpcFuture<ResponseType>`, which implements the
`com.google.common.util.concurrent.ListenableFuture` interface.

The future stub contains one Java method for each unary method in the service
definition. Future stubs do not support streaming calls.

A new future stub is instantiated via the `ServiceNameGrpc.newFutureStub(Channel
channel)` static method.

#### Unary

The future stub signature for a unary RPC method `unaryExample`:

```java
public ListenableFuture<ResponseType> unaryExample(RequestType request)
```

## Codegen

Typically the build system handles creation of the gRPC generated code.

For protobuf-based codegen, you can put your `.proto` files in the `src/main/proto`
and `src/test/proto` directories along with an appropriate plugin.

A typical [protobuf-maven-plugin][] configuration for generating gRPC and Protocol
Buffers code would look like the following:

```xml
<build>
  <extensions>
    <extension>
      <groupId>kr.motd.maven</groupId>
      <artifactId>os-maven-plugin</artifactId>
      <version>1.4.1.Final</version>
    </extension>
  </extensions>
  <plugins>
    <plugin>
      <groupId>org.xolstice.maven.plugins</groupId>
      <artifactId>protobuf-maven-plugin</artifactId>
      <version>0.5.0</version>
      <configuration>
        <protocArtifact>com.google.protobuf:protoc:3.3.0:exe:${os.detected.classifier}</protocArtifact>
        <pluginId>grpc-java</pluginId>
        <pluginArtifact>io.grpc:protoc-gen-grpc-java:1.4.0:exe:${os.detected.classifier}</pluginArtifact>
      </configuration>
      <executions>
        <execution>
          <goals>
            <goal>compile</goal>
            <goal>compile-custom</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

Eclipse and NetBeans users should also look at `os-maven-plugin`'s
[IDE documentation](https://github.com/trustin/os-maven-plugin#issues-with-eclipse-m2e-or-other-ides).

[protobuf-maven-plugin]: https://www.xolstice.org/protobuf-maven-plugin/

A typical [protobuf-gradle-plugin][] configuration would look like the following:

```gradle
apply plugin: 'java'
apply plugin: 'com.google.protobuf'

buildscript {
  repositories {
    mavenCentral()
  }
  dependencies {
    // ASSUMES GRADLE 2.12 OR HIGHER. Use plugin version 0.7.5 with earlier
    // gradle versions
    classpath 'com.google.protobuf:protobuf-gradle-plugin:0.8.0'
  }
}

protobuf {
  protoc {
    artifact = "com.google.protobuf:protoc:3.2.0"
  }
  plugins {
    grpc {
      artifact = 'io.grpc:protoc-gen-grpc-java:1.4.0'
    }
  }
  generateProtoTasks {
    all()*.plugins {
      grpc {}
    }
  }
}
```

[protobuf-gradle-plugin]: https://github.com/google/protobuf-gradle-plugin

Bazel developers can use the
[`java_grpc_library`](https://github.com/grpc/grpc-java/blob/master/java_grpc_library.bzl)
rule, typically as follows:

```java
load("@grpc_java//:java_grpc_library.bzl", "java_grpc_library")

proto_library(
    name = "helloworld_proto",
    srcs = ["src/main/proto/helloworld.proto"],
)

java_proto_library(
    name = "helloworld_java_proto",
    deps = [":helloworld_proto"],
)

java_grpc_library(
    name = "helloworld_java_grpc",
    srcs = [":helloworld_proto"],
    deps = [":helloworld_java_proto"],
)
```

Android developers, see [Generating client code](/docs/platforms/android/java/basics/#generating-client-code) for reference.

If you wish to invoke the protobuf plugin for gRPC Java directly,
the command-line syntax is as follows:

```sh
protoc --plugin=protoc-gen-grpc-java \
    --grpc-java_out="$OUTPUT_FILE" --proto_path="$DIR_OF_PROTO_FILE" "$PROTO_FILE"
```
