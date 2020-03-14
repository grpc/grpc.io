---
title: About gRPC
description: Who is using it, why they're using it, and which platforms support it
---

gRPC is a modern open source high performance RPC framework that can run in any
environment. It can efficiently connect services in and across data centers with
pluggable support for load balancing, tracing, health checking and
authentication. It is also applicable in last mile of distributed computing to
connect devices, mobile applications and browsers to backend services.

### The main usage scenarios

* Efficiently connecting polyglot services in microservices style architecture
* Connecting mobile devices, browser clients to backend services
* Generating efficient client libraries

### Core features that make it awesome

* Idiomatic client libraries in 10 languages
* Highly efficient on wire and with a simple service definition framework
* Bi-directional streaming with http/2 based transport
* Pluggable auth, tracing, load balancing and health checking

## Who’s using gRPC and why?

Many companies are already using gRPC for connecting multiple services in their
environments. The use case varies from connecting a handful of services to
hundreds of services across various languages in on-prem or cloud environments.
Below are details and quotes from some of our early adopters.

Check out what people are saying below.

{{< testimonials >}}

## Officially supported languages and platforms

{{< supported-platforms >}}

## The story behind gRPC

Google has been using a single general-purpose RPC infrastructure called Stubby
to connect the large number of microservices running within and across our data
centers for over a decade. Our internal systems have long embraced the
microservice architecture gaining popularity today. Stubby has powered all of
Google’s microservices interconnect for over a decade and is the RPC backbone
behind every Google service that you use today. In March 2015, we decided to
build the next version of Stubby in the open so we can share our learnings with
the industry and collaborate with them to build the next version of Stubby both
for microservices inside and outside Google but also for last mile of computing
(mobile, web and IOT).

For more background on why we created gRPC, see the [gRPC Motivation and Design
Principles](/blog/principles) on the [gRPC blog](/blog).
