---
author: Mahak Mukhi
company: Google
company-link: google.com
date: "2017-08-22T00:00:00Z"
published: true
title: 2017-08-22 gRPC-Go performance Improvements
---
<p>
<span style="margin-bottom:5%">For past few months we've been working on improving gRPC-Go performance. This includes improving network utilization, optimizing CPU usage and memory allocations. Most of our recent effort has been focused around revamping gRPC-Go flow control. After several optimizations and new features we've been able to improve quite significantly, especially on high-latency networks. We expect users that are working with high-latency networks and large messages to see an order of magnitude performance gain.
Benchmark results at the end.

This blog summarizes the work we have done so far (in chronological order) to improve performance and lays out our near-future plans.</style>
</p><br>
<!--more-->

### Recently Implemented Optimizations


###### Expanding stream window on receiving large messages

[Code link](https://github.com/grpc/grpc-go/pull/1248)

This is an optimization used by gRPC-C to achieve performance benefits for large messages. The idea is that when there's an active read by the application on the receive side, we can effectively bypass stream-level flow control to request the whole message. This proves to be very helpful with large messages. Since the application is already committed to reading and has allocated enough memory for it, it makes sense that we send a proactive large window update (if necessary) to get the whole message rather than receiving it in chunks and sending window updates when we run low on window.

This optimization alone provided a 10x improvement for large messages on high-latency networks.


###### Decoupling application reads from connection flow control

[Code link](https://github.com/grpc/grpc-go/pull/1265)

After having several discussions with gRPC-Java and gRPC-C core team we realized that gRPC-Go's connection-level flow control was overly restrictive in the sense that window updates on the connection depended upon if the application had read data from it or not. It must be noted that it makes perfect sense to have stream-level flow control depended on application read but not so much for connection-level flow control. The rationale is as follows: A connection is shared by several streams (RPCs). If there were at least one stream that read slowly or didn't read at all, it would hamper the performance or completely stall other streams on that connection. This happens because we won't send out window updates on the connection until that slow or inactive stream read data. Therefore, it makes sense to decouple the connection's flow control from application reads.

However, this begs at least two questions:

1. Won't a client be able to send as much data as it wants to the server by creating new streams when one runs out?

2. Why even have connection-level flow control if the stream-level flow control is enough?

The answer to the first question is short and simple: no. A server has an option to limit the number of streams that it intends to serve concurrently. Therefore, although at first it may seem like a problem, it really is not.

The need for connection-level flow control:

It is true that stream-level flow control is sufficient to throttle a sender from sending too much data. But not having connection-level flow control (or using an unlimited connection-level window) makes it so that when things get slower on a stream, opening a new one will appear to make things faster. This will only take one so far since the number of streams are limited. However, having a connection-level flow control window set to the Bandwidth Delay Product (BDP) of the network puts an upper-bound on how much performance can realistically be squeezed out of the network.


###### Piggyback window updates

[Code link](https://github.com/grpc/grpc-go/pull/1273)

Sending a window update itself has a cost associated to it; a flush operation is necessary, which results in a syscall. Syscalls are blocking and slow. Therefore, when sending out a stream-level window update, it makes sense to also check if a connection-level window update can be sent using the same flush syscall.


###### BDP estimation and dynamic flow control window

[Code link](https://github.com/grpc/grpc-go/pull/1310)

This feature is the latest and in some ways the most awaited optimization feature that has helped us close the final gap between gRPC and HTTP/1.1 performance on high latency networks.

Bandwidth Delay Product (BDP) is the bandwidth of a network connection times its round-trip latency.  This effectively tells us how many bytes can be "on the wire" at a given moment, if full utilization is achieved.

The [algorithm](https://docs.google.com/document/d/1Eq4eBEbNt1rc8EYuwqsduQd1ZfcBOCYt9HVSBa--m-E/pub) to compute BDP and adapt accordingly was first proposed by @ejona and later implemented by both gRPC-C core and gRPC-Java (note that it isn't enabled in Java yet). The idea is simple and powerful: every time a receiver gets a data frame it sends out a BDP ping (a ping with unique data only used by BDP estimator). After this, the receiver starts counting the number of bytes it receives (including the ones that triggered the BDP ping) until it receives the ack for that ping. This total sum of all bytes received in about 1.5 RTT (Round-Trip Time) is an approximation of the effective BDP * 1.5. If this is close to our current window size (say, more than 2/3rd of it) we must increase the window size. We put our window sizes (both streaming and connection) to be twice the BDP we sampled(total sum of all bytes received).

This algorithm by itself could cause the BDP estimation to increase indefinitely; an increase in window will result in sampling more bytes which in turn will cause the window to be increased further. This phenomenon is called [buffer-bloat](https://en.wikipedia.org/wiki/Bufferbloat) and was discovered by earlier implementations in gRPC-C core and gRPC-Java. The solution to this is to calculate the bandwidth for every sample and check if it is greater than the maximum bandwidth noted so far. If so, only then increase our window sizes. The bandwidth, as we know, can be calculated by dividing the sample by RTT * 1.5 (remember the sample was for one and a half round trips). If the bandwidth doesn't increase with an increase in sampled bytes that's indicative that this change is because of an increased window size and doesn't really reflect the nature of the network itself.

While running experiments on VMs in different continents we realized that every once in awhile a rogue, unnaturally fast ping-ack at the right time (really the wrong time) would cause our window sizes to go up. This happens because such a ping-ack would cause us to notice a decreased RTT and calculate a high bandwidth value. Now if that sample of bytes was greater than 2/3rd of our window then we would increase the window sizes. However, this ping ack was an aberration and shouldn't have changed our perception of the network RTT al together. Therefore, we keep a running average of the RTTs we note weighted by a constant rather than the total number of samples to heed more to recent RTTs and less to the ones in past. It is important because networks might change over time.

During implementation, we experimented with several tuning parameters, such as the multiplier to compute the window size from the sample size to select the best settings, that balanced between growth and accuracy.

Given that we're always bound by the flow control of TCP which for most cases is upper bounded at 4MB, we bound the growth of our window sizes by the same number: 4MB.

BDP estimation and dynamically adjusting window sizes is turned-on by default and can be turned off by setting values manually for connection and/or stream window sizes.


###### Near-future efforts

We are now looking into improving our throughput by better CPU utilization, the following efforts are in-line with that.


###### Reducing flush syscalls

We noticed a bug in our transport layer which causes us to make a flush syscall for every data frame we write, even if the same goroutine has more data to send. We can batch a lot of these writes to use only one flush. This in fact will not be a big change to the code itself.

In our efforts to get rid of unnecessary flushes we recently combined the headers and data write for unary and server streaming RPCs to one flush on the client-side. Link to [code](https://github.com/grpc/grpc-go/pull/1343)

Another related idea proposed by one of our users @petermattic in [this](https://github.com/grpc/grpc-go/pull/1373) PR was to combine a server response to a unary RPC into one flush. We are currently looking into that as well.


###### Reducing memory allocation

For every data frame read from the wire a new memory allocation takes place. The same holds true at the gRPC layer for every new message for decompressing and decoding. These allocations result in excessive garbage collection cycles, which are expensive. Reusing memory buffers can reduce this GC pressure, and we are prototyping approaches to do so. As requests need buffers of differing sizes, one approach would be to maintain individual memory pools of fixed sizes (powers of two). So now when reading x bytes from the wire we can find the nearest power of 2 greater than x and reuse a buffer from our cache if available or allocate a new one if need be. We will be using golang sync Pools so we don't have to worry about garbage collection. However, we will need to run sufficient tests before committing to this.



###### Results:


* Benchmark on a real network:

  * Server and client were launched on two VMs in different continents. RTT of ~152ms.
  * Client made an RPC with a payload and server responded back with an empty message.
  * The time taken for each RPC was measured.
  * [Code link](https://github.com/grpc/grpc-go/compare/master...MakMukhi:http_greeter)


<table>
<tr><th>Message Size </th><th>GRPC </th><th>HTTP 1.1</th></tr>

<tr><td>1 KB</td><td>~152 ms</td><td>~152 ms</td></tr>
<tr><td>10 KB</td><td>~152 ms</td><td>~152 ms</td></tr>
<tr><td>10 KB</td><td>~152 ms</td><td>~152 ms</td></tr>
<tr><td>1 MB</td><td>~152 ms</td><td>~152 ms</td></tr>
<tr><td>10 MB</td><td>~622 ms</td><td>~630 ms</td></tr>
<tr><td>100 MB</td><td>~5 sec</td><td>~5 sec</td></tr>


</table>

* Benchmark on simulated network:
  * Server and client were launched on the same machine and different network latencies were simulated.
  * Client made an RPC with 1MB of payload and server responded back with an empty message.
  * The time taken for each RPC was measured.
  * Following tables show time taken by first 10 RPCs.
  * [Code link](https://github.com/grpc/grpc-go/compare/master...MakMukhi:grpc_vs_http)

##### No Latency Network

| GRPC | HTTP 2.0 | HTTP 1.1 |
| --------------|:-------------:|-----------:|
|5.097809ms|16.107461ms|18.298959ms |  
|4.46083ms|4.301808ms|7.715456ms
|5.081421ms|4.076645ms|8.118601ms
|4.338013ms|4.232606ms|6.621028ms
|5.013544ms|4.693488ms|5.83375ms
|3.963463ms|4.558047ms|5.571579ms
|3.509808ms|4.855556ms|4.966938ms
|4.864618ms|4.324159ms|6.576279ms
|3.545933ms|4.61375ms|6.105608ms
|3.481094ms|4.621215ms|7.001607ms

##### Network with RTT of 16ms

| GRPC | HTTP 2.0 | HTTP 1.1 |
| --------------|:-------------:|-----------:|
|118.837625ms|84.453913ms|58.858109ms
|36.801006ms|22.476308ms|20.877585ms
|35.008349ms|21.206222ms|19.793881ms
|21.153461ms|20.940937ms|22.18179ms
|20.640364ms|21.888247ms|21.4666ms
|21.410346ms|21.186008ms|20.925514ms
|19.755766ms|21.818027ms|20.553768ms
|20.388882ms|21.366796ms|21.460029ms
|20.623342ms|20.681414ms|20.586908ms
|20.452023ms|20.781208ms|20.278481ms

##### Network with RTT of 64ms

| GRPC | HTTP 2.0 | HTTP 1.1 |
| --------------|:-------------:|-----------:|
|455.072669ms|275.290241ms|208.826314ms
|195.43357ms|70.386788ms|70.042513ms
|132.215978ms|70.01131ms|71.19429ms
|69.239273ms|70.032237ms|69.479335ms
|68.669903ms|70.192272ms|70.858937ms
|70.458108ms|69.395154ms|71.161921ms
|68.488057ms|69.252731ms|71.374758ms
|68.816031ms|69.628744ms|70.141381ms
|69.170105ms|68.935813ms|70.685521ms
|68.831608ms|69.728349ms|69.45605ms
