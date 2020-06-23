---
title: ALTS on Google Cloud Platform (GCP)
description: >
  An overview of gRPC ALTS authentication running on Google Cloud Platform.
---

### Overview

[ALTS](ALTS) is now available to all gRPC users, if the application runs on
[Google Compute Engine (GCE)](https://cloud.google.com/compute/) or
[Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine).
The detailed instructions on how to use ALTS as an authentication mechanism
in gRPC can be found in [ALTS Authentiction guide](ALTS).

### Identity and Key Management

Using ALTS transport security protocol on Google Cloud Platform, the identity
of the gRPC application is the primary service account associated with the GCE
VM that the application runs on. The service account of a GCE VM can be set or
changed using
[gCloud command](https://cloud.google.com/sdk/gcloud/reference/compute/instances/set-service-account)
or via
[GCP console](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#using).

Google Cloud Platform issues an ALTS credential for each service account running
on the GCE VM. The ALTS credentials are securely located in the hypervisor. The
private key of an ALTS credential is not accessible to the VM and the
application. The session keys used for end-to-end encryption are exposed to the
gRPC stack. Google Cloud Platform fully manages the ALTS credentials, including
certificate issuing, certificate rotation, and certification revocation.
