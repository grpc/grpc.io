---
spelling: cSpell:ignore channelz keepalives mainpage Yuxuan zpages
title: A short introduction to Channelz
date: 2018-09-05
author:
  name: Yuxuan Li
  link: https://github.com/lyuxuan
---

Channelz is a tool that provides comprehensive runtime info about connections at
different levels in gRPC. It is designed to help debug live programs, which may
be suffering from network, performance, configuration issues, etc. The
[gRFC](https://github.com/grpc/proposal/blob/master/A14-channelz.md) provides a
detailed explanation of channelz design and is the canonical reference for all
channelz implementations across languages. The purpose of this blog is to
familiarize readers with channelz service and how to use it for debugging
issues. The context of this post is set in
[gRPC-Go](https://github.com/grpc/grpc-go), but the overall idea should be
applicable across languages. At the time of writing, channelz is available for
[gRPC-Go](https://github.com/grpc/grpc-go) and
[gRPC-Java](https://github.com/grpc/grpc-java). Support for
[C++](https://github.com/grpc/grpc) and wrapped languages is coming soon.

<!--more-->

Let's learn channelz through a simple example which uses channelz to help debug
an issue. The
[helloworld](https://github.com/grpc/grpc-go/tree/master/examples/helloworld)
example from our repo is slightly modified to set up a buggy scenario. You can
find the full source code here:
[client](https://gist.github.com/lyuxuan/515fa6da7e0924b030e29b8be56fd90a),
[server](https://gist.github.com/lyuxuan/81dd08ca649a6c78a61acc7ab05e0fef).

> **Client setup:**
> The client will make 100 SayHello RPCs to a specified target and load balance
> the workload with the round robin policy. Each call has a 150ms timeout. RPC
> responses and errors are logged for debugging purposes.

Running the program, we notice in the log that there are intermittent errors
with error code **DeadlineExceeded**, as shown in Figure 1.

However, there's no clue about what is causing the deadline exceeded error and
there are many possibilities:

* Network issue, for example: connection lost
* Proxy issue, for example: dropped requests/responses in the middle
* Server issue, for example: lost requests or just slow to respond

![](/img/log.png)
<p style="text-align: center"> Figure 1. Program log screenshot</p>

Let's turn on grpc INFO logging for more debug info and see if we can find
something helpful.

![](/img/logWithInfo.png)
<p style="text-align: center"> Figure 2. gRPC INFO log</p>

As shown in Figure 2, the info log indicates that all three connections to the
server are connected and ready for transmitting RPCs. No suspicious event shows
up in the log. One thing that can be inferred from the info log is that all
connections are up all the time, therefore the lost connection hypothesis can be
ruled out.

To further narrow down the root cause of the issue, we will ask channelz for
help.

Channelz provides gRPC internal networking machinery stats through a gRPC
service. To enable channelz, users just need to register the channelz service to
a gRPC server in their program and start the server. The code snippet below
shows the API for registering channelz service to a
[grpc.Server](https://godoc.org/google.golang.org/grpc#Server). Note that this
has already been done for our example client.

```go
import "google.golang.org/grpc/channelz/service"

// s is a *grpc.Server
service.RegisterChannelzServiceToServer(s)

// call s.Serve() to serve channelz service
```

A web tool called
[grpc-zpages](https://github.com/grpc/grpc-experiments/tree/master/gdebug)
has been developed to conveniently serve channelz data through a web page.
First, configure the web app to connect to the gRPC port that's serving the
channelz service (see instructions from the previous link). Then, open the
channelz web page in the browser. You should see a web page like Figure 3. Now
we can start querying channelz!

![](/img/mainpage.png)
<p style="text-align: center"> Figure 3. Channelz main page</p>

As the error is on the client side, let's first click on
[TopChannels](https://github.com/grpc/proposal/blob/master/A14-channelz.md#gettopchannels).
TopChannels is a collection of root channels which don't have parents. In
gRPC-Go, a top channel is a
[ClientConn](https://godoc.org/google.golang.org/grpc#ClientConn) created by the
user through [NewClient](https://godoc.org/google.golang.org/grpc#NewClient),
and used for making RPC calls. Top channels are of
[Channel](https://github.com/grpc/grpc-proto/blob/9b13d199cc0d4703c7ea26c9c330ba695866eb23/grpc/channelz/v1/channelz.proto#L37)
type in channelz, which is an abstraction of a connection that an RPC can be
issued to.

![](/img/topChan1.png)
<p style="text-align: center"> Figure 4. TopChannels result</p>

So we click on the TopChannels, and a page like Figure 4 appears, which lists
all the live top channel(s) with related info.

As shown in Figure 5, there is only one top channel with id = 2 (Note that text
in square brackets is the reference name of the in memory channel object, which
may vary across languages).

Looking at the **Data** section, we can see there are 15 calls failed out of 100
on this channel.

![](/img/topChan2.png)
<p style="text-align: center"> Figure 5. Top Channel (id = 2)</p>

On the right hand side, it shows the channel has no child **Channels**, 3
**Subchannels** (as highlighted in Figure 6), and 0 **Sockets**.

![](/img/topChan3.png)
<p style="text-align: center"> Figure 6. Subchannels owned by the Channel (id = 2)</p>

A
[Subchannel](https://github.com/grpc/grpc-proto/blob/9b13d199cc0d4703c7ea26c9c330ba695866eb23/grpc/channelz/v1/channelz.proto#L61)
is an abstraction over a connection and used for load balancing. For example,
you want to send requests to "google.com". The resolver resolves "google.com" to
multiple backend addresses that serve "google.com". In this example, the client
is set up with the round robin load balancer, so all live backends are sent
equal traffic. Then the (logical) connection to each backend is represented as a
Subchannel. In gRPC-Go, a
[SubConn](https://godoc.org/google.golang.org/grpc/balancer#SubConn) can be seen
as a Subchannel.

The three Subchannels owned by the parent Channel means there are three
connections to three different backends for sending the RPCs to. Let's look
inside each of them for more info.

So we click on the first Subchannel ID (i.e. "4\[\]") listed, and a page like
Figure 7 renders. We can see that all calls on this Subchannel have succeeded.
Thus it's unlikely this Subchannel is related to the issue we are having.

![](/img/subChan4.png)

<p style="text-align: center"> Figure 7. Subchannel (id = 4)</p>

So we go back, and click on Subchannel 5 (i.e. "5\[\]"). Again, the web page
indicates that Subchannel 5 also never had any failed calls.

![](/img/subChan6_1.png)
<p style="text-align: center"> Figure 8. Subchannel (id = 6)</p>

And finally, we click on Subchannel 6. This time, there's something different.
As we can see in Figure 8, there are 15 out of 34 RPC calls failed on this
Subchannel. And remember that the parent Channel also has exactly 15 failed
calls. Therefore, Subchannel 6 is where the issue comes from. The state of the
Subchannel is **READY**, which means it is connected and is ready to transmit
RPCs. That rules out network connection problems. To dig up more info, let's
look at the Socket owned by this Subchannel.

A
[Socket](https://github.com/grpc/grpc-proto/blob/9b13d199cc0d4703c7ea26c9c330ba695866eb23/grpc/channelz/v1/channelz.proto#L227)
is roughly equivalent to a file descriptor, and can be generally regarded as the
TCP connection between two endpoints. In grpc-go,
[http2Client](https://github.com/grpc/grpc-go/blob/ce4f3c8a89229d9db3e0c30d28a9f905435ad365/internal/transport/http2_client.go#L46)
and
[http2Server](https://github.com/grpc/grpc-go/blob/ce4f3c8a89229d9db3e0c30d28a9f905435ad365/internal/transport/http2_server.go#L61)
correspond to Socket. Note that a network listener is also considered a Socket,
and will show up in the channelz Server info.

![](/img/subChan6_2.png)
<p style="text-align: center"> Figure 9. Subchannel (id = 6) owns Socket (id = 8)</p>

We click on Socket 8, which is at the bottom of the page (see Figure 9). And we
now see a page like Figure 10.

The page provides comprehensive info about the socket like the security
mechanism in use, stream count, message count, keepalives, flow control numbers,
etc. The socket options info is not shown in the screenshot, as there are a lot
of them and not related to the issue we are investigating.

The **Remote Address** field suggests that the backend we are having a problem
with is **"127.0.0.1:10003"**. The stream counts here correspond perfectly to
the call counts of the parent Subchannel. From this, we can know that the server
is not actively sending DeadlineExceeded errors. This is because if the
DeadlineExceeded error is returned by the server, then the streams would all be
successful. A client side stream's success is independent of whether the call
succeeds. It is determined by whether a HTTP2 frame with EOS bit set has been
received (refer to the
[gRFC](https://github.com/grpc/proposal/blob/master/A14-channelz.md#socket-data)
for more info). Also, we can see that the number of messages sent is 34, which
equals the number of calls, and it rules out the possibility of the client being
stuck somehow and results in deadline exceeded. In summary, we can narrow down
the issue to the server which serves on 127.0.0.1:10003. It may be that the
server is slow to respond, or some proxy in front of it is dropping requests.

![](/img/socket8.png)
<p style="text-align: center"> Figure 10. Socket (id = 8)</p>

As you see, channelz has helped us pinpoint the potential root cause of the
issue with just a few clicks. You can now concentrate on what's happening with
the pinpointed server. And again, channelz may help expedite the debugging at
the server side too.

We will stop here and let readers explore the server side channelz, which is
simpler than the client side. In channelz, a
[Server](https://github.com/grpc/grpc-proto/blob/9b13d199cc0d4703c7ea26c9c330ba695866eb23/grpc/channelz/v1/channelz.proto#L199)
is also an RPC entry point like a Channel, where incoming RPCs arrive and get
processed. In grpc-go, a
[grpc.Server](https://godoc.org/google.golang.org/grpc#Server) corresponds to a
channelz Server. Unlike Channel, Server only has Sockets (both listen socket(s)
and normal connected socket(s)) as its children.

Here are some hints for the readers:

* Look for the server with the address (127.0.0.1:10003).
* Look at the call counts.
* Go to the Socket(s) owned by the server.
* Look at the Socket stream counts and message counts.

You should notice that the number of messages received by the server socket is
the same as sent by the client socket (Socket 8), which rules out the case of
having a misbehaving proxy (dropping request) in the middle. And the number of
messages sent by the server socket is equal to the messages received at client
side, which means the server was not able to send back the response before
deadline. You may now look at the
[server](https://gist.github.com/lyuxuan/81dd08ca649a6c78a61acc7ab05e0fef) code
to verify whether it is indeed the cause.

> **Server setup:**
> The server side program starts up three GreeterServers, with two of them using
> an implementation
> ([server](https://gist.github.com/lyuxuan/81dd08ca649a6c78a61acc7ab05e0fef#file-main-go-L42))
> that imposes no delay when responding to the client, and one using an
> implementation
> ([slowServer](https://gist.github.com/lyuxuan/81dd08ca649a6c78a61acc7ab05e0fef#file-main-go-L50))
> which injects a variable delay of 100ms - 200ms before sending the response.

As you can see through this demo, channelz helped us quickly narrow down the
possible causes of an issue and is easy to use. For more resources, see the
detailed channelz
[gRFC](https://github.com/grpc/proposal/blob/master/A14-channelz.md). Find us on
GitHub at [github.com/grpc/grpc-go](https://github.com/grpc/grpc-go).
