---
title: "How robots talk: building distributed robots with gRPC and WebRTC"
date: 2025-04-30
author:
  name: Joyce Lin
  position: Viam
  link: https://www.linkedin.com/in/joyce-lin/
  guest: true
---

If you're building any kind of distributed machine, like robots, drones, or IoT devices, two questions come up fast:

- How do you send structured commands and data efficiently?
- How do you keep communication resilient when you have an unreliable network?

In this article, I’ll share the approach we use at [Viam](https://www.viam.com/), an open-source robotics platform that combines gRPC for structured RPCs and WebRTC for peer-to-peer streaming. Even if you're not building robots, the same architectural ideas can help you design more scalable and adaptable systems.

## Bridging the gap between lab-grade robotics and real-world systems

[ROS](https://en.wikipedia.org/wiki/Robot_Operating_System) (Robot Operating System) has long been the go-to framework for building and prototyping robotics systems, especially in research and academia. It works well on trusted, local networks because that’s what it was designed for.

But today's robots don’t stay on tightly-regulated lab benches. They're deployed on factory floors, out at sea, or in remote fields, where network conditions are unpredictable and reliability matters.

ROS doesn’t handle network communication out of the box. If you need to talk to a robot over the internet, you’re on your own to architect the solution. Modern robotics requires more than local LAN protocols. It needs cloud-ready, peer-to-peer, resilient communication stacks.

Rather than relying on a distributed messaging stack like MQTT or relaying commands through the cloud, Viam uses gRPC and WebRTC to power [its robotics platform](https://docs.viam.com/#platform). Used together, these protocols offer a modern alternative that complements ROS’s strengths. gRPC provides structured, language-agnostic APIs with fast, efficient Protobuf serialization. And WebRTC adds low-latency, peer-to-peer connections, which is ideal for streaming sensor data or real-time video between machines.

Some robot builders are also layering gRPC interfaces on top of ROS, blending ROS’s rich ecosystem with the modern transport and scalability of gRPC.

## Why gRPC makes sense for robots

Modern robots are no longer single-purpose machines in fixed environments. They're mobile, multi-part systems that need to collaborate with sensors, perception services, and control loops, often in real time.

gRPC supports these needs in several key ways:

- **Low-latency, real-time control**: gRPC enables continuous, bidirectional streams, allowing systems to send real-time pose updates to a robotic arm, while simultaneously receiving telemetry, without additional round-trip delays.
- **Cross-platform, multi-language consistency**: gRPC automatically generates client libraries (stubs) for languages like Python, Go, C++, and others, making it easier to bridge different devices, SDKs, and environments with a consistent interface.
- **Lightweight and efficient serialization**: gRPC also helps in bandwidth-constrained environments or on embedded devices, enabled by Protobuf’s lightweight binary encoding.
- **Security benefits**: gRPC is designed with end-to-end encryption (TLS by default) and authentication capabilities baked in, ensuring secure communication between machine parts, whether across local networks or the public internet, without requiring developers to bolt on separate security layers.
- **Service abstraction for machine parts**: With gRPC and Protobuf, every part of a robot, from motors to cameras to sensors, can be modeled as a standardized, language-agnostic service.
  ![Every robot part becomes an encapsulated, language-agnostic service](/img/blog/robotics/component-protos.png)

In [Viam’s public API](https://github.com/viamrobotics/api), each robot component is defined as a gRPC service using Protobuf. Components like arms, cameras, and sensors expose typed methods that can be called remotely. Here's an excerpt from the [`arm.proto`](https://github.com/viamrobotics/api/blob/main/proto/viam/component/arm/v1/arm.proto) file that defines basic movement and pose retrieval methods for a robotic arm:

```proto
// An ArmService services all arms associated with a robot
service ArmService {
  rpc MoveToPosition (MoveToPositionRequest) returns (MoveToPositionResponse);
  rpc GetEndPosition (GetEndPositionRequest) returns (GetEndPositionResponse);
  rpc GetJointPositions(GetJointPositionsRequest) returns (GetJointPositionsResponse);
}
```

These proto services can then generate [SDKs](https://docs.viam.com/dev/reference/sdks/) to help you work with your machines. This example uses the Python SDK to move an arm. Under the hood, gRPC handles encoding the command into a Protobuf message and sending it over HTTP/2 (or WebRTC, depending on the environment).

```python
from viam.components.arm import ArmClient

arm = ArmClient.from_robot(robot=robot, name="my-arm")

# Move the arm to a target 3D position
arm.move_to_position(x=0.1, y=0.2, z=0.3, orientation=None, world_state=None)
```

## Why WebRTC is also part of the picture

At first glance, gRPC and WebRTC might seem redundant. Both can stream data and send structured messages. But they solve very different challenges in robotics.

WebRTC excels at direct, peer-to-peer connections, which is essential when:

- Devices are on local networks or constrained by NAT/firewalls
- You want to bypass a central relay or cloud server
- You’re streaming high-bandwidth sensor data (like real-time video or LIDAR) between machines

Viam uses gRPC for orchestration and WebRTC as the underlying transport, combining them for fast, structured messaging with minimal routing overhead.

## Flexible transport layers with gRPC

While WebRTC enables peer-to-peer communication in distributed machines, gRPC also offers flexibility to swap underlying transport layers.

Here is [an example gRPC server that runs over WebRTC and other transport protocols](https://github.com/viamrobotics/goutils/tree/main/rpc/examples/echo). Viam also uses Unix domain sockets (UDS) for local messaging between the `viam-server` and internal modules, Bluetooth for provisioning machines or proxying network traffic, and serial ports for embedded peripherals.

Because gRPC defines a consistent interface at the API layer, we can change the transport depending on the environment or device without rewriting client logic, a huge strength when building systems that span cloud, local, and constrained networks.

## A real-world example: coordinating a claw game

Picture a remote-controlled claw machine, like the ones you'd find in an arcade. It has two main components: a camera and a robotic arm. A user interface, such as a [web app](https://docs.viam.com/dev/reference/sdks/#frontend-sdks) or [mobile app](https://docs.viam.com/dev/reference/sdks/#mobile-sdk), sends control commands and receives a live video stream to help guide the claw to its prize.

![Viam enclosed robotic arm as a claw game at a conference](/img/blog/robotics/viam-enclosed-robotic-arm.jpg)

Here's how gRPC and WebRTC work together behind the scenes:

- **Initialization**: The system establishes control channels using gRPC over HTTP/2. Each component registers its services (e.g. `ArmService`, `CameraService`).
- **Connection**: gRPC coordinates the exchange of peer metadata and signaling to set up a WebRTC session between the SDK and machine parts.
- **Real-time operation**: WebRTC now handles the media and data streams directly between peers. Commands are sent using gRPC method calls, routed over the WebRTC transport. Video and sensor streams flow the other way.

![Viam uses gRPC to initialize connections and WebRTC for peer-to-peer communication in this robot claw game](/img/blog/robotics/grpc-and-webrtc.png)

This dual-protocol approach allows real-time interaction, smooth streaming, and resilient fallback behavior, even in unpredictable network conditions.

## Why this pattern matters for the broader community

The combination of gRPC’s structure and WebRTC’s flexibility opens the door to a new class of distributed systems, not just in robotics, but anywhere you need:

- Real-time, bi-directional communication between loosely-coupled systems
- Typed, versioned APIs that span languages and devices
- Transport-agnostic flexibility, with the option to go peer-to-peer when needed

gRPC structures the conversation. WebRTC carries it across the network.

## Viam for real-time robot control

gRPC has evolved far beyond simple request/response APIs. Across many industries beyond robotics, the way machines communicate is more critical than ever. gRPC and WebRTC aren’t just faster protocols, they’re influential building blocks for the next generation of distributed, resilient, and intelligent machines.

If you’re building systems that need to talk to each other across devices, environments, and networks, it might be time to explore a more scalable and adaptable communication layer.

While you could engineer a similar stack on your own, [Viam](https://www.viam.com/) offers these capabilities out of the box. The on-machine functionality is open-source and free to operate, with optional cloud services available on a usage-based model when you scale to fleets.

_Technical review by [Nick Hehr](https://www.linkedin.com/in/nick-hehr/) (Viam)_
