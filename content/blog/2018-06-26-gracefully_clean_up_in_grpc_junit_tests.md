---
author: Dapeng Zhang
author-link: https://github.com/dapengzhang0
company: Google
company-link: https://www.google.com
date: "2018-06-26T00:00:00Z"
published: true
title: Gracefully clean up in gRPC JUnit tests
url: blog/gracefully_clean_up_in_grpc_junit_tests
---

It is best practice to always clean up gRPC resources such as client channels, servers, and previously attached Contexts whenever they are no longer needed. 

This is even true for JUnit tests, because otherwise leaked resources may not only linger in your machine forever, but also interfere with subsequent tests. A not-so-bad case is that subsequent tests can't pass because of a leaked resource from the previous test. The worst case is that some subsequent tests pass that wouldn't have passed at all if the previously passed test had not leaked a resource.

<!--more-->

So cleanup, cleanup, cleanup... and fail the test if any cleanup is not successful.

A typical example is

```java
public class MyTest {
  private Server server;
  private ManagedChannel channel;
  ...
  @After
  public void tearDown() throws InterruptedException {
    // assume channel and server are not null
    channel.shutdownNow();
    server.shutdownNow();
    // fail the test if cleanup is not successful
    assert channel.awaitTermination(5, TimeUnit.SECONDS) : "channel failed to shutdown";
    assert server.awaitTermination(5, TimeUnit.SECONDS) : "server failed to shutdown";
  }
  ...
}
```

or to be more graceful

```java
public class MyTest {
  private Server server;
  private ManagedChannel channel;
  ...
  @After
  public void tearDown() throws InterruptedException {
    // assume channel and server are not null
    channel.shutdown();
    server.shutdown();
    // fail the test if cannot gracefully shutdown
    try {
      assert channel.awaitTermination(5, TimeUnit.SECONDS) : "channel cannot be gracefully shutdown";
      assert server.awaitTermination(5, TimeUnit.SECONDS) : "server cannot be gracefully shutdown";
    } finally {
      channel.shutdownNow();
      server.shutdownNow();
    }
  }
  ...
}
```

However, having to add all this to every test so it shuts down gracefully gives you more work to do, as you need to write the shutdown boilerplate by yourself. Because of this, the gRPC testing library has helper rules to make this job less tedious.

Initially, a JUnit rule [`GrpcServerRule`][GrpcServerRule] was introduced to eliminate the shutdown boilerplate. This rule creates an In-Process server and channel at the beginning of the test, and shuts them down at the end of test automatically. However, users found this rule too restrictive in that it does not support transports other than In-Process transports, multiple channels to the server, custom channel or server builder options, and configuration inside individual test methods.

A more flexible JUnit rule [`GrpcCleanupRule`][GrpcCleanupRule] was introduced in gRPC release v1.13, which also eliminates the shutdown boilerplate. However unlike `GrpcServerRule`, `GrpcCleanupRule` does not create any server or channel automatically at all. Users create and start the server by themselves, and create channels by themselves, just as in plain tests. With this rule, users just need to register every resource (channel or server) that needs to be shut down at the end of test, and the rule will then shut them down gracefully automatically.

You can register resources either before running test methods

```java
public class MyTest {
  @Rule
  public GrpcCleanupRule grpcCleanup = new GrpcCleanupRule();
  ...
  private String serverName = InProcessServerBuilder.generateName();
  private Server server = grpcCleanup.register(InProcessServerBuilder
      .forName(serverName).directExecutor().addService(myServiceImpl).build().start());
  private ManagedChannel channel = grpcCleanup.register(InProcessChannelBuilder
      .forName(serverName).directExecutor().build());
  ...
}
```

or inside each individual test method

```java
public class MyTest {
  @Rule
  public GrpcCleanupRule grpcCleanup = new GrpcCleanupRule();
  ...
  private String serverName = InProcessServerBuilder.generateName();
  private InProcessServerBuilder serverBuilder = InProcessServerBuilder
      .forName(serverName).directExecutor();
  private InProcessChannelBuilder channelBuilder = InProcessChannelBuilder
      .forName(serverName).directExecutor();
  ...

  @Test
  public void testFooBar() {
    ...
    grpcCleanup.register(
    	serverBuilder.addService(myServiceImpl).build().start());
    ManagedChannel channel = grpcCleanup.register(
    	channelBuilder.maxInboundMessageSize(1024).build());
    ...
  }
}
```

Now with [`GrpcCleanupRule`][GrpcCleanupRule] you don't need to worry about graceful shutdown of gRPC servers and channels in JUnit test. So try it out and clean up in your tests!

[GrpcServerRule]:https://github.com/grpc/grpc-java/blob/v1.1.x/testing/src/main/java/io/grpc/testing/GrpcServerRule.java
[GrpcCleanupRule]:https://github.com/grpc/grpc-java/blob/v1.13.x/testing/src/main/java/io/grpc/testing/GrpcCleanupRule.java
