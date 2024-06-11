---
title: OpenTelemetry Metrics
description: >-
  OpenTelemetry Metrics available in gRPC
---

### Overview

gRPC provides in-built support for an OpenTelemetry plugin that provides metrics that can help you troubleshoot your system, iterate on improving system performance and setup continuous monitoring and alerting.

### Background

OpenTelemetry is an observability framework to create and manage telemetry data. gRPC previously provided observability support through OpenCensus which has been [sunsetted](https://opentelemetry.io/blog/2023/sunsetting-opencensus/) in the favor of OpenTelemetry.

### Client Per-Attempt Instruments

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.client.attempt.started | Counter | {attempt} | grpc.method, grpc.target | The total number of RPC attempts started, including those that have not completed. |
| grpc.client.attempt.duration | Histogram | s | grpc.method, grpc.target, grpc.status | End-to-end time taken to complete an RPC attempt including the time it takes to pick a subchannel. |
| grpc.client.attempt.sent_total_compressed_message_size | Histogram | By | grpc.method, grpc.target, grpc.status | Total bytes (compressed but not encrypted) sent across all request messages (metadata excluded) per RPC attempt; does not include grpc or transport framing bytes. |
| grpc.client.attempt.rcvd_total_compressed_message_size | Histogram | By | grpc.method, grpc.target | Total bytes (compressed but not encrypted) received across all response messages (metadata excluded) per RPC attempt; does not include grpc or transport framing bytes. |

Refer [A66: OpenTelemetry Metrics] for details.

### Client Per-Call Instruments

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.client.call.duration | Histogram | s | grpc.method, grpc.target , grpc.status | This metric aims to measure the end-to-end time the gRPC library takes to complete an RPC from the application’s perspective. |

Refer [A66: OpenTelemetry Metrics] for details.

### Server Instruments

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.server.call.started | Counter | {call} | grpc.method | The total number of RPCs started, including those that have not completed. |
| grpc.server.call.sent_total_compressed_message_size | Histogram | By | grpc.method, grpc.status | Total bytes (compressed but not encrypted) sent across all response messages (metadata excluded) per RPC; does not include grpc or transport framing bytes. |
| grpc.server.call.rcvd_total_compressed_message_size | Histogram | By | grpc.method, grpc.status | Total bytes (compressed but not encrypted) received across all request messages (metadata excluded) per RPC; does not include grpc or transport framing bytes. |
| grpc.server.call.duration | Histogram | s | grpc.method, grpc.status      | This metric aims to measure the end2end time an RPC takes from the server transport’s (HTTP2/ inproc) perspective. |

Refer [A66: OpenTelemetry Metrics] for details.

### LB Policy Instruments

#### Weighted Round Robin LB Policy Instruments

| Name | Type | Unit | Labels (disposition) | Description |
|------|------|------|--------|-------------|
| grpc.lb.wrr.rr_fallback | Counter | {update} | grpc.target (required), grpc.lb.locality (optional) | Number of scheduler updates in which there were not enough endpoints with valid weight, which caused the WRR policy to fall back to RR behavior. |
| grpc.lb.wrr.endpoint_weight_not_yet_usable | Counter | {endpoint} | grpc.target (required), grpc.lb.locality (optional) | Number of endpoints from each scheduler update that don't yet have usable weight information (i.e., either the load report has not yet been received, or it is within the blackout period). |
| grpc.lb.wrr.endpoint_weight_stale | Counter | {endpoint} | grpc.target (required), grpc.lb.locality (optional) | Number of endpoints from each scheduler update whose latest weight is older than the expiration period. |
| grpc.lb.wrr.endpoint_weights | Histogram | {weight} | grpc.target (required), grpc.lb.locality (optional) | Weight of an endpoint recorded every scheduler update. |

Refer [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient] for details.

#### Pick First LB Policy Instruments

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.lb.pick_first.disconnections | Counter | {disconnection} | grpc.target | Number of times the selected subchannel becomes disconnected. |
| grpc.lb.pick_first.connection_attempts_succeeded | Counter | {attempt} | grpc.target | Number of successful connection attempts. |
| grpc.lb.pick_first.connection_attempts_failed | Counter | {attempt} | grpc.target | Number of failed connection attempts. |

Refer [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient] for details.

### XdsClient Instruments 

| Name | Type | Unit | Labels (required) | Description |
|------|------|------|--------|-------------|
| grpc.xds_client.connected | Gauge | {bool} | grpc.target, grpc.xds.server | Whether or not the xDS client currently has a working ADS stream to the xDS server. |
| grpc.xds_client.server_failure | Counter | {failure} | grpc.target, grpc.xds.server | A counter of xDS servers going from healthy to unhealthy. |
| grpc.xds_client.resource_updates_valid | Counter | {resource} | grpc.target, grpc.xds.server, grpc.xds.resource_type | A counter of resources received that were considered valid, even if unchanged. |
| grpc.xds_client.resource_updates_invalid | Counter | {resource} | grpc.target, grpc.xds.server, grpc.xds.resource_type | A counter of resources received that were considered invalid. |
| grpc.xds_client.resources | Gauge | {resource} | grpc.target, grpc.xds.authority, grpc.xds.cache_state, grpc.xds.resource_type | Number of xDS resources. |

Refer [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient] for details.

### Attributes

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

### FAQ

### Language examples

| Language | Example          |
|----------|------------------|
| C++      | [C++ Example]    |
| Python   | [Python Example] |


### Additional Resources

* [A66: OpenTelemetry Metrics]
* [A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient]
* [A79: Non-per-call Metrics Architecture]

[C++ Example]: https://github.com/grpc/grpc/tree/master/examples/cpp/otel
[Python Example]: https://github.com/grpc/grpc/tree/master/examples/python/observability
[A66: OpenTelemetry Metrics]: https://github.com/grpc/proposal/blob/master/A66-otel-stats.md
[A78: gRPC OTel Metrics for WRR, Pick First, and XdsClient]: https://github.com/grpc/proposal/blob/master/A78-grpc-metrics-wrr-pf-xds.md
[A79: Non-per-call Metrics Architecture]: https://github.com/grpc/proposal/blob/master/A79-non-per-call-metrics-architecture.md#a79-non-per-call-metrics-architecture
