---
title: gRPC + JSON
date: 2018-08-15
spelling: cSpell:ignore Cap’n Gson kvstore Mastrangelo
author:
  name: Carl Mastrangelo
  link: https://carlmastrangelo.com
  position: Google
---

So you've bought into this whole RPC thing and want to try it out, but aren't quite sure about Protocol Buffers.  Your existing code encodes your own objects, or perhaps you have code that needs a particular encoding.  What to do?

Fortunately, gRPC is encoding agnostic!  You can still get a lot of the benefits of gRPC without using Protobuf.  In this post we'll go through how to make gRPC work with other encodings and types.  Let's try using JSON.

<!--more-->

gRPC is actually a collection of technologies that have high cohesion, rather than a singular, monolithic framework.  This means its possible to swap out parts of gRPC and still take advantage of gRPC's benefits.  [Gson](https://github.com/google/gson) is a popular library for Java for doing JSON encoding.  Let's remove all the protobuf related things and replace them with Gson:

```diff
- Protobuf wire encoding
- Protobuf generated message types
- gRPC generated stub types
+ JSON wire encoding
+ Gson message types
```

Previously, Protobuf and gRPC were generating code for us, but we would like to use our own types.  Additionally, we are going to be using our own encoding too.  Gson allows us to bring our own types in our code, but provides a way of serializing those types into bytes.

Let's continue with the [Key-Value](https://github.com/carl-mastrangelo/kvstore/tree/04-gson-marshaller) store service.  We will be modifying the code used my previous [So You Want to Optimize gRPC](/blog/optimizing-grpc-part-2/) post.

## What is a Service Anyways?

From the point of view of gRPC, a _Service_ is a collection of _Methods_.  In Java, a method is represented as a [MethodDescriptor](https://grpc.io/grpc-java/javadoc/io/grpc/MethodDescriptor.html).  Each `MethodDescriptor` includes the name of the method, a `Marshaller` for encoding requests, and a `Marshaller` for encoding responses.  They also include additional detail, such as if the call is streaming or not.  For simplicity, we'll stick with unary RPCs which have a single request and single response.

Since we won't be generating any code, we'll need to write the message classes ourselves.  There are four methods, each which have a request and a response type.  This means we need to make eight messages:

```java
  static final class CreateRequest {
    byte[] key;
    byte[] value;
  }

  static final class CreateResponse {
  }

  static final class RetrieveRequest {
    byte[] key;
  }

  static final class RetrieveResponse {
    byte[] value;
  }

  static final class UpdateRequest {
    byte[] key;
    byte[] value;
  }

  static final class UpdateResponse {
  }

  static final class DeleteRequest {
    byte[] key;
  }

  static final class DeleteResponse {
  }
```

Because GSON uses reflection to determine how the fields in our classes map to the serialized JSON, we don't need to annotate the messages.

Our client and server logic will use the request and response types, but gRPC needs to know how to produce and consume these messages.  To do this, we need to implement a [Marshaller](https://grpc.io/grpc-java/javadoc/io/grpc/MethodDescriptor.Marshaller.html).  A marshaller knows how to convert from an arbitrary type to an `InputStream`, which is then passed down into the gRPC core library.  It is also capable of doing the reverse transformation when decoding data from the network.  For GSON, here is what the marshaller looks like:

```java
  static <T> Marshaller<T> marshallerFor(Class<T> clz) {
    Gson gson = new Gson();
    return new Marshaller<T>() {
      @Override
      public InputStream stream(T value) {
        return new ByteArrayInputStream(gson.toJson(value, clz).getBytes(StandardCharsets.UTF_8));
      }

      @Override
      public T parse(InputStream stream) {
        return gson.fromJson(new InputStreamReader(stream, StandardCharsets.UTF_8), clz);
      }
    };
  }
```

Given a `Class` object for a some request or response, this function will produce a marshaller.  Using the marshallers, we can compose a full `MethodDescriptor` for each of the four CRUD methods.  Here is an example of the Method descriptor for _Create_:

```java
  static final MethodDescriptor<CreateRequest, CreateResponse> CREATE_METHOD =
      MethodDescriptor.newBuilder(
          marshallerFor(CreateRequest.class),
          marshallerFor(CreateResponse.class))
          .setFullMethodName(
              MethodDescriptor.generateFullMethodName(SERVICE_NAME, "Create"))
          .setType(MethodType.UNARY)
          .build();
```

Note that if we were using Protobuf, we would use the existing Protobuf marshaller, and the
[method descriptors](https://github.com/carl-mastrangelo/kvstore/blob/03-nonblocking-server/build/generated/source/proto/main/grpc/io/grpc/examples/proto/KeyValueServiceGrpc.java#L44)
would be generated automatically.

## Sending RPCs

Now that we can marshal JSON requests and responses, we need to update our
[KvClient](https://github.com/carl-mastrangelo/kvstore/blob/b225d28c7c2f3c356b0f3753384b3329f2ab5911/src/main/java/io/grpc/examples/KvClient.java#L98),
the gRPC client used in the previous post, to use our MethodDescriptors.  Additionally, since we won't be using any Protobuf types, the code needs to use `ByteBuffer` rather than `ByteString`.  That said, we can still use the `grpc-stub` package on Maven to issue the RPC.  Using the _Create_ method again as an example, here's how to make an RPC:

```java
    ByteBuffer key = createRandomKey();
    ClientCall<CreateRequest, CreateResponse> call =
        chan.newCall(KvGson.CREATE_METHOD, CallOptions.DEFAULT);
    KvGson.CreateRequest req = new KvGson.CreateRequest();
    req.key = key.array();
    req.value = randomBytes(MEAN_VALUE_SIZE).array();

    ListenableFuture<CreateResponse> res = ClientCalls.futureUnaryCall(call, req);
    // ...
```

As you can see, we create a new `ClientCall` object from the `MethodDescriptor`, create the request, and then send it using `ClientCalls.futureUnaryCall` in the stub library.  gRPC takes care of the rest for us.  You can also make blocking stubs or async stubs instead of future stubs.

## Receiving RPCs

To update the server, we need to create a key-value service and implementation.  Recall that in gRPC, a _Server_ can handle one or more _Services_.  Again, what Protobuf would normally have generated for us we need to write ourselves.  Here is what the base service looks like:

```java
  static abstract class KeyValueServiceImplBase implements BindableService {
    public abstract void create(
        KvGson.CreateRequest request, StreamObserver<CreateResponse> responseObserver);

    public abstract void retrieve(/*...*/);

    public abstract void update(/*...*/);

    public abstract void delete(/*...*/);

    /* Called by the Server to wire up methods to the handlers */
    @Override
    public final ServerServiceDefinition bindService() {
      ServerServiceDefinition.Builder ssd = ServerServiceDefinition.builder(SERVICE_NAME);
      ssd.addMethod(CREATE_METHOD, ServerCalls.asyncUnaryCall(
          (request, responseObserver) -> create(request, responseObserver)));

      ssd.addMethod(RETRIEVE_METHOD, /*...*/);
      ssd.addMethod(UPDATE_METHOD, /*...*/);
      ssd.addMethod(DELETE_METHOD, /*...*/);
      return ssd.build();
    }
  }
```

`KeyValueServiceImplBase` will serve as both the service definition (which describes which methods the server can handle) and as the implementation (which describes what to do for each method).  It serves as the glue between gRPC and our application logic.  Practically no changes are needed to swap from Proto to GSON in the server code:

```java
final class KvService extends KvGson.KeyValueServiceImplBase {

  @Override
  public void create(
      KvGson.CreateRequest request, StreamObserver<KvGson.CreateResponse> responseObserver) {
    ByteBuffer key = ByteBuffer.wrap(request.key);
    ByteBuffer value = ByteBuffer.wrap(request.value);
    // ...
  }
```

After implementing all the methods on the server, we now have a fully functioning gRPC Java, JSON encoding RPC system.  And to show you there is nothing up my sleeve:

```sh
./gradlew :dependencies | grep -i proto
# no proto deps!
```

## Optimizing the Code

While Gson is not as fast as Protobuf, there's no sense in not picking the low hanging fruit.  Running the code we see the performance is pretty slow:

```sh
./gradlew installDist
time ./build/install/kvstore/bin/kvstore

INFO: Did 215.883 RPCs/s
```

What happened?  In the previous [optimization](/blog/optimizing-grpc-part-2/) post, we saw the Protobuf version do nearly _2,500 RPCs/s_.  JSON is slow, but not _that_ slow.  We can see what the problem is by printing out the JSON data as it goes through the marshaller:

```json
{"key":[4,-100,-48,22,-128,85,115,5,56,34,-48,-1,-119,60,17,-13,-118]}
```

That's not right!  Looking at a `RetrieveRequest`, we see that the key bytes are being encoded as an array, rather than as a byte string.  The wire size is much larger than it needs to be, and may not be compatible with other JSON code.  To fix this, let's tell GSON to encode and decode this data as base64 encoded bytes:

```java
  private static final Gson gson =
      new GsonBuilder().registerTypeAdapter(byte[].class, new TypeAdapter<byte[]>() {
    @Override
    public void write(JsonWriter out, byte[] value) throws IOException {
      out.value(Base64.getEncoder().encodeToString(value));
    }

    @Override
    public byte[] read(JsonReader in) throws IOException {
      return Base64.getDecoder().decode(in.nextString());
    }
  }).create();
```

Using this in our marshallers, we can see a dramatic performance difference:

```sh
./gradlew installDist
time ./build/install/kvstore/bin/kvstore

INFO: Did 2,202.2 RPCs/s
```

Almost **10x** faster than before!  We can still take advantage of gRPC's efficiency while bringing our own encoders and messages.

## Conclusion

gRPC lets you use encoders other than Protobuf.  It has no dependency on Protobuf and was specially made to work with a wide variety of environments.  We can see that with a little extra boilerplate, we can use any encoder we want.  While this post only covered JSON, gRPC is compatible with Thrift, Avro, Flatbuffers, Cap’n Proto, and even raw bytes!  gRPC lets you be in control of how your data is handled.  (We still recommend Protobuf though due to strong backwards compatibility, type checking, and performance it gives you.)

All the code is available on [GitHub](https://github.com/carl-mastrangelo/kvstore/tree/04-gson-marshaller) if you would like to see a fully working implementation.
