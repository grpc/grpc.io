---
title: "Health Checking TLS gRPC Servers"
date: 2026-08-21
spelling: cSpell:ignore Amritansh kubelet Prometheus protobuf Bowei Kanzhelev
author:
  name: Amritansh
  link: https://github.com/amritansh1502
  position: Associate Software Engineer at [Red Hat](https://www.redhat.com)
  guest: true
---

gRPC's [health checking protocol](/docs/guides/health-checking/) is itself a
gRPC service. That is intentional: a health check is an RPC, with the same
deadlines, status codes, and [transport security](/docs/guides/auth/) as every
other call. If your server only accepts TLS, a plaintext client never gets far
enough to ask whether you are `SERVING`.

<!--more-->

That mismatch has been a practical problem for gRPC services running in
Kubernetes. Native gRPC probes call `grpc.health.v1.Health/Check` directly, but
until now they always dialed with insecure credentials. A TLS-only server
looked unhealthy even when it was fine. Kubernetes 1.37 closes that gap: the
probe can use TLS transport credentials, the same way any other gRPC client
would.

## Why health-check over gRPC instead of HTTP/1.1

Teams often consider exposing a separate HTTP/1.1 `/healthz` endpoint just so
an orchestrator can probe the process. For a gRPC service that is the wrong
protocol on a second port. gRPC already has a standard Health service, and it
is a better fit for three reasons.

**Binary payloads.** HTTP health endpoints typically speak JSON or plain text.
gRPC uses [Protocol Buffers](https://protobuf.dev): a compact binary encoding
that is cheaper to serialize and smaller on the wire. A payload that is about
1 KB as JSON is often a few hundred bytes as protobuf. The Health `Check`
request and response are tiny either way, but you stay on one encoding for
application RPCs and health RPCs.

**HTTP/2, not a new TCP connection per check.** gRPC runs on
[HTTP/2](/blog/grpc-on-http2/). Streams multiplex over a single connection, so
application traffic does not pay HTTP/1.1's usual one-request-at-a-time (or
new-connection) cost. A Health `Check` is just another RPC on that same
transport. You do not need a second listener, extra ingress rules, or a
plaintext HTTP port whose only job is to tell Kubernetes the process is alive.

**No process fork, no extra binary.** Before native gRPC probes, health-checking
a gRPC server on Kubernetes meant an `exec` probe (fork a new process every few
seconds, ship a ~14 MB static binary in every image) or that extra HTTP/1.1
listener. Native probes eliminate both: the kubelet is a gRPC client. It dials
over HTTP/2 and calls `Health/Check` in-process. No fork, no extra port.

## Native probes almost made exec probes obsolete

Before Kubernetes 1.23, every team running gRPC on Kubernetes had to bundle
[grpc-health-probe](https://github.com/grpc-ecosystem/grpc-health-probe) and
invoke it as an `exec` probe. That binary has been downloaded more than
38 million times from
GitHub releases, and as Google
[noted](https://cloud.google.com/blog/topics/developers-practitioners/health-checking-your-grpc-servers-gke),
it is "used in production at many companies using gRPC in part of their stack,
including Google."

The alternative — a dedicated HTTP/1.1 health port, meant a second listener,
more surface area to harden, and a health signal that was not the same RPC
your clients use. Neither approach scaled well.

That is why [KEP-2727](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/2727-grpc-probe)
added native gRPC probes to the kubelet: alpha in 1.23, beta in 1.24, GA in
1.27. The kubelet dials the pod over HTTP/2, calls `Check` on the standard
[gRPC Health Checking Protocol](https://github.com/grpc/grpc/blob/master/doc/health-checking.md),
and maps `SERVING` to success. No extra binary, no extra process, no extra
port.

## Health checking is an RPC

gRPC specifies the API in
[`grpc.health.v1`](https://github.com/grpc/grpc-proto/blob/master/grpc/health/v1/health.proto).
Servers implement the `Health` service and report status per service name, or
for the whole process using the empty string:

```protobuf
service Health {
  rpc Check(HealthCheckRequest) returns (HealthCheckResponse);
  rpc Watch(HealthCheckRequest) returns (stream HealthCheckResponse);
}
```

`Check` is the unary RPC that load balancers, monitoring systems, and
orchestrators use for a one-shot probe. `Watch` is the streaming RPC that
gRPC clients use to keep a channel's view of backend health up to date.

Because both methods are ordinary RPCs, they inherit the server's credentials.
A server created with TLS channel credentials will not complete a plaintext
handshake. The probe never reaches `Check`, so you never see `SERVING` or
`NOT_SERVING` — only a failed connection. That is a transport problem, not an
application health signal.

## TLS-only servers were still stuck

Native probes shipped with a hard limitation: they only dialed plaintext. In
production that is a real problem. Many gRPC services enforce TLS on every
connection, including internal ones, with certificates from a private CA.

When the kubelet's plaintext `Health/Check` hits a TLS-only server, the
handshake fails immediately. Kubernetes marks the container unhealthy even
though the service is fine. Teams were forced back to the same `exec` workaround
native probes were supposed to replace:

```yaml
livenessProbe:
  exec:
    command:
      - /bin/grpc_health_probe
      - -addr=:8443
      - -tls
      - -tls-no-verify
```

The community put it plainly in
[kubernetes/kubernetes#119093](https://github.com/kubernetes/kubernetes/issues/119093):
"Setting up a gRPC server to use plaintext is not really acceptable in
production, so built-in probes are kind of unusable."

[KEP-4939](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/4939-grpc-probe-with-tls)
adds one optional field to the existing gRPC probe API. Set `mode: TLS` and
the kubelet uses TLS transport credentials:

```yaml
livenessProbe:
  grpc:
    port: 8443
    mode: TLS   # new in Kubernetes 1.37
```

`mode` is `Plaintext` or `TLS`. Omit it and the probe stays plaintext, so
existing servers are unchanged.

This is alpha in 1.37, gated by `GRPCContainerProbeTLS` on the API server and
the kubelet.

## The probe is a gRPC client

The kubelet creates a channel to the container, calls `Check`, and treats
`SERVING` as success. What changed is the channel credentials:

```go
var transportCreds credentials.TransportCredentials
if useTLS {
    // Encrypt the probe RPC. Skip hostname verification: the kubelet
    // dials the pod IP, which is not in the certificate SAN.
    transportCreds = credentials.NewTLS(&tls.Config{
        InsecureSkipVerify: true,
    })
} else {
    transportCreds = insecure.NewCredentials()
}

conn, err := grpc.DialContext(ctx, addr,
    grpc.WithTransportCredentials(transportCreds),
)
```

The RPC, the proto, and the status values are unchanged. Only the transport
matches the server.

Skipping verification is a probe-specific choice, the same idea as Kubernetes
HTTPS probes. Pod IPs are ephemeral and do not appear in a certificate's SAN,
so there is no hostname to check. This is **not** a model for application
clients: those should keep using proper TLS credentials
and verify the server. The probe also does not present a client certificate,
so mTLS-required servers will still reject it.

## What gRPC servers should do

You do not need a second listener, a sidecar, or an HTTP health endpoint.
Register the standard Health service on the same TLS-enabled server that
serves your application RPCs, and keep the serving status in sync with
readiness:

```go
import (
    "log"
    "net"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials"
    "google.golang.org/grpc/health"
    healthgrpc "google.golang.org/grpc/health/grpc_health_v1"
)

creds, err := credentials.NewServerTLSFromFile(certFile, keyFile)
if err != nil {
    log.Fatal(err)
}

s := grpc.NewServer(grpc.Creds(creds))

healthcheck := health.NewServer()
healthgrpc.RegisterHealthServer(s, healthcheck)
pb.RegisterGreeterServer(s, &server{})

// Empty service name is the process-wide status the probe uses by default.
healthcheck.SetServingStatus("", healthgrpc.HealthCheckResponse_SERVING)
healthcheck.SetServingStatus("example.Greeter", healthgrpc.HealthCheckResponse_SERVING)

lis, err := net.Listen("tcp", ":8443")
if err != nil {
    log.Fatal(err)
}
if err := s.Serve(lis); err != nil {
    log.Fatal(err)
}
```

The same pattern exists in every supported language. See the
health checking guide for examples in Java, Go, Python, and C++.

Set the status to `NOT_SERVING` when the process should not receive traffic
— during startup, while a dependency is down, or before graceful shutdown.
That is the signal probes and gRPC client-side health checking both
understand.

If you want the probe to check one service rather than the whole process,
set `service` in the probe spec to the same name you pass to
`SetServingStatus`.

## Native TLS probes are much cheaper than exec

We compared the two ways to health-check TLS gRPC servers: `exec` with
`grpc_health_probe -tls -tls-no-verify`, versus native `grpc.mode: TLS`. Each
group ran 50 pods. Probe latency was scraped with Prometheus.

| Probe | How it runs | Average latency |
| --- | --- | --- |
| Exec (`grpc_health_probe`) | Fork a process, start the Go runtime, TLS dial, `Check`, exit | ~40 ms |
| Native `mode: TLS` | In-process kubelet dial + `Check` | ~6 ms |

The native TLS probe is consistently about 6–7× faster. The exec path pays for
a new process on every invocation. The native path is a TLS handshake and a
Health RPC inside the kubelet — the overhead gRPC was designed to keep small.

## Check vs Watch

Orchestrator probes and gRPC clients both speak the Health protocol, but they
use different RPCs:

| | Orchestrator probe | gRPC client |
| --- | --- | --- |
| RPC | Unary `Check` | Streaming `Watch` |
| When | Periodically, from outside the process | For the life of the subchannel |
| Purpose | Restart or withhold traffic at the platform | Avoid sending RPCs to an unhealthy backend |
| Transport | Whatever the probe is configured to use | The channel's credentials, including TLS |

Enabling TLS on the probe does not replace client-side health checking. If
your gRPC clients already watch backend health
over TLS, keep doing that. The probe answers a different question: should
this container stay in the Service, and should it be restarted?

If you hit problems with the Health RPC itself, the
[gRPC mailing list](https://groups.google.com/g/grpc-io) and language-specific
GitHub repos are the right place. For the Kubernetes probe client, see
KEP-4939.

gRPC has had a standard health API and first-class TLS for a long time. The
useful change is that a widely used health client can now use both at once.
