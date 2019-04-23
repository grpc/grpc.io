---
title: "About gRPC"
date: 2018-09-11T14:11:42+07:00
draft: false
---

gRPC is a modern open source high performance RPC framework that can run in any environment. It can efficiently connect services in and across data centers with pluggable support for load balancing, tracing, health checking and authentication. It is also applicable in last mile of distributed computing to connect devices, mobile applications and browsers to backend services.

<b>The main usage scenarios:</b>

* Efficiently connecting polyglot services in microservices style architecture
* Connecting mobile devices, browser clients to backend services
* Generating efficient client libraries

<b>Core Features that make it awesome:</b>

* Idiomatic client libraries in 10 languages
* Highly efficient on wire and with a simple service definition framework
* Bi-directional streaming with http/2 based transport
* Pluggable auth, tracing, load balancing and health checking

<hr>

## Cases: Who’s using it and why?

Many companies are already using gRPC for connecting multiple services in their environments. The use case varies from connecting a handful of services to hundreds of services across various languages in on-prem or cloud environments. Below are details and quotes from some of our early adopters.

Check out what people are saying below:



<div class="testimonialrow">
<div class="testimonialsection">
<div>
    <a href="https://www.youtube.com/watch?v=-2sWDr3Z0Wo">
      <div class="testimonialimage">  <img src="../img/square-icon.png" style="width:45%"/></a></div>
        <div>
            <div class="testimonialquote">“ </div>
              At Square, we have been collaborating with Google so that we can replace all uses of our custom RPC solution to use gRPC.  We decided to move to gRPC because of its open support for multiple platforms, the demonstrated performance of the protocol, and the ability to customize and adapt it to our network.  Developers at Square are looking forward to being able to take advantage of writing streaming APIs and in the future, push gRPC to the edges of the network for integration with mobile clients and third party APIs.
        </div>          

</div>
</div>

<div class="testimonialsection">
    <div class="testimonialimage"><a href="https://github.com/Netflix/ribbon">
        <img src="../img/netflix-logo.png" /> </a></div>
         <div>
            <div class="testimonialquote"> “ </div>
            In our initial use of gRPC we've been able to extend it easily to live within our opinionated ecosystem.  Further, we've had great success making improvements directly to gRPC through pull requests and interactions with Google's team that manages the project.  We expect to see many improvements to developer productivity, and the ability to allow development in non-JVM languages as a result of adopting gRPC.
        </div>

</div>
<div class="testimonialsection">
    <div class="testimonialimage"><a href="https://blog.gopheracademy.com/advent-2015/etcd-distributed-key-value-store-with-grpc-http2/">
        <img src="../img/coreos-1.png" style="width:30%"/></a></div>
        <div>
            <div class="testimonialquote">“ </div>
            At CoreOS we are excited by the gRPC v1.0 release and the opportunities it opens up for people consuming and building what we like to call Google Infrastructure for Everyone Else. Today gRPC is in use in a number of our critical open source projects such as the etcd consensus database and the rkt container engine.
        </div>           

</div>
</div>
<div class="testimonialsection">
  <div class="testimonialimage">  <a href="https://github.com/cockroachdb/cockroach">
        <img src="../img/cockroach-1.png" />  </a></div>
        <div>
            <div class="testimonialquote">“ </div>
            Our switch from a home-grown RPC system to gRPC was seamless. We quickly took advantage of the per-stream flow control to provide better scheduling of large RPCs over the same connection as small ones.
        </div>

</div>

<div class="testimonialsection">
    <div class="testimonialimage"><a href="https://github.com/CiscoDevNet/grpc-getting-started">
        <img src="../img/cisco.svg" /></a></div>
        <div>
          <div class="testimonialquote">“ </div>
            With support for high performance bi-directional streaming, TLS based security, and a wide variety of programming languages, gRPC is an ideal unified transport protocol for model driven configuration and telemetry.
        </div>

</div>

<div class="testimonialsection">
    <div class="testimonialimage"><a href="http://www.carbon3d.com">
        <img src="../img/carbon3d.svg" /></a></div>
        <div>
            <div class="testimonialquote">“ </div>
            Carbon3D uses gRPC to implement distributed processes both within and outside our 3D printers. We actually switched from using Thrift early on for a number of reasons including but not limited to robust support for multiple languages like C++, Nodejs and Python. Features like bi-directional streaming are a huge win in keeping our systems implementations simpler and correct. Lastly the gRPC team/community is very active and responsive which is also a key factor for us in selecting an open source technology for mission critical projects.
        </div>

</div>

<div class="testimonialsection">
        <div class="testimonialimage"><img src="../img/wisc-mad.jpg" /></a></div>
        <div>
            <div class="testimonialquote">“ </div>
            We've been using gRPC for both classes and research at University of Wisconsin. Students in our distributed systems class (CS 739) utilized many of its powerful features when building their own distributed systems. In addition, gRPC is a key component of our OpenLambda research project (https://www.open-lambda.org/) which aims to provide an open-source, low-latency, serverless computational framework.
        </div>
</div>

<div class="testimonialsection">
  <div class="testimonialimage"><a href="https://github.com/Juniper/open-nti">
    <img src="../img/juniperlogo.png" />  </a></div>
    <div>
        <div class="testimonialquote">“ </div>
        The fact that gRPC is built on HTTP/2 transport brings us native bi-directional streaming capabilities and flexible custom-metadata in request headers.  The first point is important for large payloadexchange and network telemetry scenarios while the latter enables us to expand and include capabilities including but not limited to various network element authentication mechanisms.

         In addition, the wide language binding support that gRPC/proto3 bringsenables us to provide a flexible and rapid development environment for both internal and external consumers.

         Last but not least, while there are a number of network communicationprotocols for configuration, operational state retrieval and network telemetry, gRPC provides us with a unified flexible protocol and transport to ease client/server interaction.
    </div>

</div>    

<div class="aboutsection2">
<h2>Officially Supported Platforms</h2>


<table style="width:80%;margin-top:5%;margin-bottom:5%">
<tr style="width:100%">
<th style="width:20%">Language           </th><th> Platform </th><th>Compiler</th>
</tr>

<tr>
<td>C/C++</td><td>Linux</td><td>GCC 4.4 <br/> GCC 4.6 <br> GCC 5.3 <br> Clang 3.5 <br> Clang 3.6 <br> Clang 3.7|</td>
</tr>

<tr>
<td>C/C++</td><td>Windows 7+</td><td>Visual Studio 2013+</td>
</tr>


<tr>
<td>C#</td><td>Windows 7+ </td><td> Linux <br> .NET Core, .NET 4.5+ <br> .NET Core, Mono 4+ <br> .NET Core, Mono 4+</td>
</tr>

<tr>
<td>Dart</td><td>Windows/Linux/Mac</td><td> Dart 2.0+</td>
</tr>


<tr>
<td>Go</td><td>Windows/Linux/Mac</td><td> Go 1.6+</td>
</tr>

<tr>
<td>Java</td><td>Windows/Linux/Mac</td><td> JDK 8 recommended. Gingerbread+ for Android</td>
</tr>

<tr>
<td>Node.js</td><td>Windows/Linux/Mac</td><td> Node v4+</td>
</tr>

<tr>
<td>PHP * </td><td>Linux/Mac</td><td> PHP 5.5+ and PHP 7.0+</td>
</tr>

<tr>
<td>Python </td><td>Windows/Linux/Mac</td><td> Python 2.7 and Python 3.4+</td>
</tr>

<tr>
<td>Ruby </td><td>Windows/Linux/Mac</td>
</tr>

</table>
<!--

| Language | Platform | Compiler |
| -------- | -------- | -------- |
| C/C++ | Linux | GCC 4.4 <br/> GCC 4.6 <br> GCC 5.3 <br> Clang 3.5 <br> Clang 3.6 <br> Clang 3.7|
| C/C++ | Windows 7+ | Visual Studio 2013+ |
| C# | Windows 7+ <br> Linux <br> Mac | .NET Core, .NET 4.5+ <br> .NET Core, Mono 4+ <br> .NET Core, Mono 4+ |
| Dart | Windows/Linux/Mac | Dart 2.0+ |
| Go | Windows/Linux/Mac | Go 1.6+ |
| Java | Windows/Linux/Mac | JDK 8 recommended. Gingerbread+ for Android |
| Node.js | Windows/Linux/Mac | Node v4+ |
| PHP * | Linux/Mac | PHP 5.5+ and PHP 7.0+ |
| Python | Windows/Linux/Mac | Python 2.7 and Python 3.4+ |
| Ruby | Windows/Linux/Mac | |
_* still in beta_
-->

<h2>The story behind gRPC</h2>
Google has been using a single general-purpose RPC infrastructure called Stubby to connect the large number of microservices running within and across our data centers for over a decade. Our internal systems have long embraced the microservice architecture gaining popularity today. Stubby has powered all of Google’s microservices interconnect for over a decade and is the RPC backbone behind every Google service that you use today. In March 2015, we decided to build the next version of Stubby in the open so we can share our learnings with the industry and collaborate with them to build the next version of Stubby both for microservices inside and outside Google but also for last mile of computing (mobile, web and IOT).
<br>
For more background on why we created gRPC, read the <a href="/blog/principles">gRPC Motivation and Design Principles blog</a>.
<br><br>
</div>
