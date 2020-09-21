---
title: gRPC in Helm
date: 2017-05-15
author:
  name: Brian Hardock
  position: Software engineer at [DEIS](https://deis.com), working on the [Helm](https://helm.sh) project
  guest: true
thumbnail: https://gabrtv.github.io/deis-dockercon-2014/img/DeisLogo.png
---

Helm is the package manager for Kubernetes. Helm provides its users with a customizable mechanism for
managing distributed applications and controlling their deployment. 

I have the good fortune to be a member of the phenomenal open-source Kubernetes Helm community serving as 
a core contributor. My first day working with the Helm team was spent prototyping the architecture for
the next generation of Helm. By the end of that day, we had procured the preliminary RPC protocol data model
used to enable communication between Helm and its in-cluster server component, Tiller.

<!--more-->

We chose to use protocol buffers - the default framework gRPC uses for serialization and over-the-air
transmission - as our data definition language. By the end of that first day hacking with the Helm team,
gRPC and protocol buffers proved to be a powerful combination. We had successfully had acheived communication
between the Helm client and Tiller server using code generated from the protobuf and gRPC service definitions.
As a personal preference, we found that the protobuf files and resulting generated gRPC
code provided an aesthetic, nearly self-documenting developer experience compared to something like Swagger.

Within a few days, the Helm team was scoping and implementing features for our users. By choosing gRPC/Proto
we had reduced the typical time spent bikeshedding that, in general, inevitably evolves from API modeling and
churning out boilerplate server code. If we had not reaped the benefits of gRPC/protobuf from day 1, we would
have spent significantly more time pivoting up and down the stack, as opposed to honing our focus on what
matters: the users and the features they requested.

In addition to serving as the Helm/Tiller communication protocol, one of our more interesting applications
of protocol buffers is that we use it to model what's referred to in Kubernetes parlance as a "Chart". Charts
are an encapsulation of Kubernetes manifests that enable you to define, install, and upgrade Kubernetes applications.
For more complex Kubernetes applications, the set of manifests may be large. By virtue of its inherent compression
capabilities, protocol buffers and gRPC allowed us to mitigate the nuisance of transmitting bulky and
sprawling Kubernetes manifests.

For a deeper dive into:

- The Helm proto, see: <https://github.com/kubernetes/helm/tree/master/_proto/hapi>
- Its generated counterpart, see: <https://github.com/kubernetes/helm/tree/master/pkg/proto/hapi>
- The interface to our Helm client, see: <https://github.com/kubernetes/helm/tree/master/pkg/helm>

In summary, protobuf and gRPC provided Helm with:

* Clearly defined message and protocol semantics for client and server communications.
* Increased feature development via a reduction in time spent on boilerplate server code / API modeling.
* High performance transmission of data through generated code and compression.
* Minimized cognitive cycles spent going from 0 to client/server communications.
