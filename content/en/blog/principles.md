---
title: gRPC Motivation and Design Principles
date: 2015-09-08
author:
  name: Louis Ryan
  position: Google
---

## Motivation

Google has been using a single general-purpose RPC infrastructure called Stubby to connect the large number of microservices running within and across our data centers for over a decade. Our internal systems have long embraced the microservice architecture gaining popularity today. Having a uniform, cross-platform RPC infrastructure has allowed for the rollout of fleet-wide improvements in efficiency, security, reliability and behavioral analysis critical to supporting the incredible growth seen in that period.

Stubby has many great features - however, it's not based on any standard and is too tightly coupled to our internal infrastructure to be considered suitable for public release. With the advent of SPDY, HTTP/2, and QUIC, many of these same features have appeared in public standards, together with other features that Stubby does not provide. It became clear that it was time to rework Stubby to take advantage of this standardization, and to extend its applicability to mobile, IoT, and Cloud use-cases.

## Principles & Requirements

### Services not Objects, Messages not References

Promote the microservices design philosophy of coarse-grained message exchange between systems while avoiding the [pitfalls of distributed objects](https://martinfowler.com/articles/distributed-objects-microservices.html) and the [fallacies of ignoring the network](https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing).

### Coverage & Simplicity

The stack should be available on every popular development platform and easy for someone to build for their platform of choice. It should be viable on CPU and memory-limited devices.

### Free & Open

Make the fundamental features free for all to use. Release all artifacts as open-source efforts with licensing that should facilitate and not impede adoption.

### Interoperability &amp; Reach

The wire protocol must be capable of surviving traversal over common internet infrastructure.

### General Purpose &amp; Performant

The stack should be applicable to a broad class of use-cases while sacrificing little in performance when compared to a use-case specific stack.

### Layered

Key facets of the stack must be able to evolve independently. A revision to the wire-format should not disrupt application layer bindings.

### Payload Agnostic

Different services need to use different message types and encodings such as protocol buffers, JSON, XML, and Thrift; the protocol and implementations must allow for this. Similarly the need for payload compression varies by use-case and payload type: the protocol should allow for pluggable compression mechanisms.

### Streaming

Storage systems rely on streaming and flow-control to express large data-sets. Other services, like voice-to-text or stock-tickers, rely on streaming to represent temporally related message sequences.

### Blocking &amp; Non-Blocking

Support both asynchronous and synchronous processing of the sequence of messages exchanged by a client and server. This is critical for scaling and handling streams on certain platforms.

### Cancellation &amp; Timeout

Operations can be expensive and long-lived - cancellation allows servers to reclaim resources when clients are well-behaved. When a causal-chain of work is tracked, cancellation can cascade. A client may indicate a timeout for a call, which allows services to tune their behavior to the needs of the client.

### Lameducking

Servers must be allowed to gracefully shut-down by rejecting new requests while continuing to process in-flight ones.

### Flow Control

Computing power and network capacity are often unbalanced between client and server. Flow control allows for better buffer management as well as providing protection from DOS by an overly active peer.

### Pluggable

A wire protocol is only part of a functioning API infrastructure. Large distributed systems need security, health-checking, load-balancing and failover, monitoring, tracing, logging, and so on. Implementations should provide extensions points to allow for plugging in these features and, where useful, default implementations.

### Extensions as APIs

Extensions that require collaboration among services should favor using APIs rather than protocol extensions where possible. Extensions of this type could include health-checking, service introspection, load monitoring, and load-balancing assignment.

### Metadata Exchange

Common cross-cutting concerns like authentication or tracing rely on the exchange of data that is not part of the declared interface of a service. Deployments rely on their ability to evolve these features at a different rate to the individual APIs exposed by services.

### Standardized Status Codes

Clients typically respond to errors returned by API calls in a limited number of ways. The status code namespace should be constrained to make these error handling decisions clearer. If richer domain-specific status is needed the metadata exchange mechanism can be used to provide that.
