---
title: OpenTelemetry Metrics
description: OpenTelemetry Metrics available in gRPC
---

## Overview

gRPC provides support for an OpenTelemetry plugin that provides metrics that can help you -
* Troubleshoot your system
* Iterate on improving system performance
* Setup continuous monitoring and alerting.

{{< youtube id="qcxdLHm2LKM" class="youtube-video" title="gRPC OpenTelemetry Metrics" >}}

## Background

OpenTelemetry is an observability framework to create and manage telemetry data. gRPC previously provided observability support through OpenCensus which has been [sunsetted](https://opentelemetry.io/blog/2023/sunsetting-opencensus/) in the favor of OpenTelemetry.

## Instruments

The gRPC OpenTelemetry plugin accepts a [MeterProvider](https://opentelemetry.io/docs/specs/otel/metrics/api/#meterprovider) and depends on the [OpenTelemetry API](https://opentelemetry.io/docs/specs/otel/overview/#api) to create a [Meter](https://opentelemetry.io/docs/specs/otel/metrics/api/#get-a-meter) that identifies the gRPC library being used, for example, `grpc-c++` at version `1.57.1`. The following listed instruments are created using this meter. Users should employ the [OpenTelemetry SDK](https://opentelemetry.io/docs/specs/otel/overview/#sdk) to customize the views exported by OpenTelemetry.

More and more gRPC components are being instrumented for observability. Currently, we have the following components instrumented -
* Per-call (stable, on by default) : Observe RPCs themselves (for example, latency.)
  * Client Per-Call : Observe a client call
  * Client Per-Attempt : Observe attempts for a client call, since a call can have multiple attempts due to retry or hedging.
  * Server : Observe a call received at the server.
* LB Policy : Observe various load-balancing policies
  * Weighted Round Robin (experimental)
  * Pick-First (experimental)
* XdsClient (experimental)

> __**NOTE**__
> Some instruments are off by default and need to be explicitly enabled from the gRPC OpenTelemetry plugin API. Experimental metrics are always off by default. ([Reference C++ API](https://github.com/grpc/grpc/blob/ccfc163607a15faa16aea179e0a0ea673c2353c6/include/grpcpp/ext/otel_plugin.h#L139))

### Per-Call Metrics

#### Client Per-Call Instruments

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.client.call.duration | Histogram | s | grpc.method, grpc.target , grpc.status | This metric aims to measure the end-to-end time the gRPC library takes to complete an RPC from the application’s perspective. |

Refer [A66: OpenTelemetry Metrics] for details.

#### Client Per-Attempt Instruments

| Name | Type | Unit | Labels (disposition) | Description |
|------|------|------|--------|-------------|
| grpc.client.attempt.<br>started | Counter | {attempt} | grpc.method (required), grpc.target (required) | The total number of RPC attempts started, including those that have not completed. |
| grpc.client.attempt.<br>duration | Histogram | s | grpc.method (required), grpc.target (required), grpc.status (required), grpc.lb.locality (optional) | End-to-end time taken to complete an RPC attempt including the time it takes to pick a subchannel. |
| grpc.client.attempt.<br>sent_total_compressed_message_size | Histogram | By | grpc.method (required), grpc.target (required), grpc.status (required), grpc.lb.locality (optional) | Total bytes (compressed but not encrypted) sent across all request messages (metadata excluded) per RPC attempt; does not include grpc or transport framing bytes. |
| grpc.client.attempt.<br>rcvd_total_compressed_message_size | Histogram | By | grpc.method (required), grpc.target (required), grpc.status (required), grpc.lb.locality (optional) | Total bytes (compressed but not encrypted) received across all response messages (metadata excluded) per RPC attempt; does not include grpc or transport framing bytes. |

Refer [A66: OpenTelemetry Metrics] for details.

#### Server Instruments

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.server.call.<br>started | Counter | {call} | grpc.method | The total number of RPCs started, including those that have not completed. |
| grpc.server.call.<br>sent_total_compressed_message_size | Histogram | By | grpc.method, grpc.status | Total bytes (compressed but not encrypted) sent across all response messages (metadata excluded) per RPC; does not include grpc or transport framing bytes. |
| grpc.server.call.<br>rcvd_total_compressed_message_size | Histogram | By | grpc.method, grpc.status | Total bytes (compressed but not encrypted) received across all request messages (metadata excluded) per RPC; does not include grpc or transport framing bytes. |
| grpc.server.call.<br>duration | Histogram | s | grpc.method, grpc.status      | This metric aims to measure the end2end time an RPC takes from the server transport’s (HTTP2/ inproc) perspective. |

Refer [A66: OpenTelemetry Metrics] for details.

### LB Policy Instruments

#### Weighted Round Robin LB Policy Instruments

| Name | Type | Unit | Labels (disposition) | Description |
|------|------|------|--------|-------------|
| grpc.lb.wrr.<br>rr_fallback | Counter | {update} | grpc.target (required), grpc.lb.locality (optional) | EXPERIMENTAL: Number of scheduler updates in which there were not enough endpoints with valid weight, which caused the WRR policy to fall back to RR behavior. |
| grpc.lb.wrr.<br>endpoint_weight_not_yet_usable | Counter | {endpoint} | grpc.target (required), grpc.lb.locality (optional) | EXPERIMENTAL: Number of endpoints from each scheduler update that don't yet have usable weight information (i.e., either the load report has not yet been received, or it is within the blackout period). |
| grpc.lb.wrr.<br>endpoint_weight_stale | Counter | {endpoint} | grpc.target (required), grpc.lb.locality (optional) | EXPERIMENTAL: Number of endpoints from each scheduler update whose latest weight is older than the expiration period. |
| grpc.lb.wrr.<br>endpoint_weights | Histogram | {weight} | grpc.target (required), grpc.lb.locality (optional) | EXPERIMENTAL: Weight of an endpoint recorded every scheduler update. |

Refer [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient] for details.

#### Pick First LB Policy Instruments

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.lb.pick_first.<br>disconnections | Counter | {disconnection} | grpc.target | EXPERIMENTAL: Number of times the selected subchannel becomes disconnected. |
| grpc.lb.pick_first.<br>connection_attempts_succeeded | Counter | {attempt} | grpc.target | EXPERIMENTAL: Number of successful connection attempts. |
| grpc.lb.pick_first.<br>connection_attempts_failed | Counter | {attempt} | grpc.target | EXPERIMENTAL: Number of failed connection attempts. |

Refer [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient] for details.

### XdsClient Instruments 

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.xds_client.<br>connected | Gauge | {bool} | grpc.target, grpc.xds.server | EXPERIMENTAL: Whether or not the xDS client currently has a working ADS stream to the xDS server. |
| grpc.xds_client.<br>server_failure | Counter | {failure} | grpc.target, grpc.xds.server | EXPERIMENTAL: A counter of xDS servers going from healthy to unhealthy. |
| grpc.xds_client.<br>resource_updates_valid | Counter | {resource} | grpc.target, grpc.xds.server, grpc.xds.resource_type | EXPERIMENTAL: A counter of resources received that were considered valid, even if unchanged. |
| grpc.xds_client.<br>resource_updates_invalid | Counter | {resource} | grpc.target, grpc.xds.server, grpc.xds.resource_type | EXPERIMENTAL: A counter of resources received that were considered invalid. |
| grpc.xds_client.<br>resources | Gauge | {resource} | grpc.target, grpc.xds.authority, grpc.xds.cache_state, grpc.xds.resource_type | EXPERIMENTAL: Number of xDS resources. |

Refer [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient] for details.

### Labels/Attributes

With a recorded measurement for an instrument, gRPC might provide some additional information as attributes or labels. For example, `grpc.client.attempt.started` has the labels `grpc.method` and `grpc.target` along with each measurement that tell us the method and the target associated with the RPC attempt being observed.

> __**NOTE**__
> Some attributes are marked as optional on the instruments. These need to be explicitly enabled from the gRPC OpenTelemetry Plugin API. ([Reference C++ API](https://github.com/grpc/grpc/blob/ccfc163607a15faa16aea179e0a0ea673c2353c6/include/grpcpp/ext/otel_plugin.h#L151))

| Name        | Description |
| ----------- | ----------- |
| grpc.method | Full gRPC method name, including package, service and method, e.g. "google.bigtable.v2.Bigtable/CheckAndMutateRow". |
| grpc.status | gRPC server status code received, e.g. "OK", "CANCELLED", "DEADLINE_EXCEEDED". |
| grpc.target | Canonicalized target URI used when creating gRPC Channel, e.g. "dns:///pubsub.googleapis.com:443", "xds:///helloworld-gke:8000". |
| grpc.lb.locality | The locality to which the traffic is being sent. |
| grpc.xds.server | For clients, indicates the target of the gRPC channel in which the XdsClient is used. For servers, will be the string "#server". |
| grpc.xds.authority | The xDS authority. The value will be "#old" for old-style non-xdstp resource names. |
| grpc.xds.cache_state |Indicates the cache state of an xDS resource ("requested", "does_not_exist", "acked", "nacked", "nacked_but_cached"). |
| grpc.xds.resource_type | xDS resource type, such as "envoy.config.listener.v3.Listener". |

## FAQ

#### Q. How do I get throughput or QPS (queries per second)?

Use a count aggregation on the latency histogram metrics - `grpc.client.attempt.duration` / `grpc.client.call.duration` (for clients) or `grpc.server.call.duration` (for servers).

#### Q. How do I get error rate for RPCs?

Error counts can be calculated by using a filter `grpc.status != OK` value on the latency histogram metrics `grpc.client.attempt.duration` / `grpc.client.call.duration` (for clients) or `grpc.server.call.duration` (for servers).


## Language examples

| Language | Example          |
|----------|------------------|
| C++      | [C++ Example]    |
| Go       | [Go Example]     |
| Java     | [Java Example]   |
| Python   | [Python Example] |


### Additional Resources

* [A66: OpenTelemetry Metrics]
* [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient]
* [A79: Non-per-call Metrics Architecture]

[C++ Example]: https://github.com/grpc/grpc/tree/master/examples/cpp/otel
[Go Example]: https://github.com/grpc/grpc-go/tree/master/examples/features/opentelemetry
[Java Example]: https://github.com/grpc/grpc-java/tree/master/examples/example-opentelemetry 
[Python Example]: https://github.com/grpc/grpc/tree/master/examples/python/observability
[A66: OpenTelemetry Metrics]: https://github.com/grpc/proposal/blob/master/A66-otel-stats.md
[A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient]: https://github.com/grpc/proposal/blob/master/A78-grpc-metrics-wrr-pf-xds.md
[A79: Non-per-call Metrics Architecture]: https://github.com/grpc/proposal/blob/master/A79-non-per-call-metrics-architecture.md#a79-non-per-call-metrics-architecture
