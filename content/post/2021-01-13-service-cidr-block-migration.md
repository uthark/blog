---
title: Performing Kubernetes Service CIDR Block Migration
date: 2021-01-13
draft: false
toc: false
categories:
- kubernetes
tags:
- kubernetes
- migration

---

In the post I describe how we did migration of Service CIDR Blocks in the fleet of our kubernetes clusters in production without downtime.

<!--more-->

Note: This is a copy of my blog post published in [Zendesk Engineering on medium](https://medium.com/zendesk-engineering/performing-kubernetes-service-cidr-block-migration-8f554cb4d4f)

# History

At Zendesk, we started our Kubernetes journey in September 2015, shortly after version 1.0 was publicly available. At the time of v1.0 not much information was available and we didn’t have a lot of experience, so some configuration choices that made sense four years ago have had to be reconsidered as the years went by.

Our clusters have seen multiple potentially disruptive migrations in production. For example in 2018, we changed the CNI implementation from flannel to AWS VPC CNI Plugin, in 2019 we migrated our etcd installation from v2 to v3 data format, and most recently we performed a Service CIDR Block migration across our live production clusters.

When we originally provisioned clusters we assumed having ClusterIPs in different clusters allocated from the same CIDR Range block would be fine since Service ClusterIPs are only resolvable in-cluster, and therefore we would be conserving valuable private IPv4 network space. So, each of our clusters was configured using the same RFC 1918 private CIDR block for service ClusterIPs.

Since that time hyper-growth in both the scale of our infrastructure and adoption of our Kubernetes platform at Zendesk has led us to consider spreading related microservices across multiple clusters, connected by service mesh technology. Clearly, having the same ClusterIP assigned to different services across clusters had downsides for service discovery and routing that needed to be fixed.

# Research

Testing quickly showed that changing the [`--service-cluster-ip-range flag`](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/) on the API Server would not be enough. Existing services would continue to use the old ClusterIPs, whereas kube-proxy would no longer populate IPTables rules for these services, whose old ClusterIPs would then be outside of the configured range. Beyond this, we found that ClusterIPs are immutable. In order to update them each service would need to be deleted and recreated to pick up it’s new IP, thus creating a short but unacceptable service interruption in production.
To overcome these issues, we performed a few rounds of research and tried different approaches for migration.
We had a brainstorming session and identified several options that might work out:

1. **Copy the service** — our first idea was to create a copy of the service and set externalIPs of the service to point to the original Cluster IP. This didn’t work out because kube-proxy ignores external IPs, assuming the underlying network will route to them directly.
1. **Migration** — using deletion of the old service and creating a new one. The idea was to set service-cluster-ip-range flag to the new CIDR block, delete the old service, create a copy of the old service using old cluster IP, and recreate the service with a new cluster IP. This didn’t work because API Server rejects to create service with ClusterIP outside of the service IP range. Moreover, after deleting the service the change is propagated everywhere and we will have small connectivity blips. Decided not to go this route.
1. **“Stale” TTL support** — our next idea was to try updating kube-proxy to add support for long lived service TTLs. This way, when a service is recreated, kube-proxy still would have to remember the old IP address and continue to route to it for some time. We decided against this option because the “stale” TTL could bring unintended results, i.e. if the migration were to be interrupted or delayed, then even our long TTL could expire, causing a service outage.
1. **Patch kube-proxy** — our final decision was to add a temporary patch to kube-proxy to support routing external IPs as if they are ClusterIPs. Extensive testing showed us that this solution would be the only solution that would ensure no service outage in production.

Finally, we outlined the following migration procedure:

1. Patch kube-proxy and add support for two service CIDR blocks — one will be covering the old service CIDR block and another one would be used for the new Service CIDR Block. Also, treat External IPs as ClusterIPs if they are part of any of known service CIDR blocks. In our setup we don’t use external IPs, and we didn’t want to extend v1.Service with new fields. Obviously, this patch was specific to our setup and couldn’t be landed upstream, so we forked [k8s.io/kubernetes](https://github.com/kubernetes/kubernetes/) and made our [small change to kube-proxy](https://github.com/uthark/kubernetes/commit/b82dc8761084400ee86acf4076c5d63a3de80e75). With this change, kube-proxy could generate IP Tables rules for multiple service CIDR blocks. So, after the change of the service-cidr-range flag on API Server, services that weren’t migrated yet still would be routable and continue to serve traffic.
1. A related patch was needed in Kubernetes API Server logic — [allow a user to update an existing Service with a different ClusterIP](https://github.com/uthark/kubernetes/commit/1152f6cd03fd0f18ea4aa745a9855c989c272022). This would allow us to update all services and assign them cluster IPs from the new Service CIDR block. This change would be disruptive without our patched version of kube-proxy
1. To perform the actual migration we developed a migration utility that would automate most of the steps and allow us to run pre-migration checks, cleanup and so on.

# Testing

With that in place, we started to test the migration in our staging infrastructure and found a few other issues:

## ServiceIP RangeAllocation object

During testing of the migration in our staging clusters, the migration would sometimes fail with an error indicating there are no free Cluster IPs available. After some digging in the kubernetes codebase, we found that there is a RangeAllocation object that stores a bitmap of used IP Addresses in the block, and if Service CIDR changes, the data becomes invalid and causes issues when new ClusterIP is allocated. So, we updated the migration procedure to stop the kube-controller-manager and remove the RangeAllocation object from etcd after confirming it wouldn’t cause any other issues.

## Certificates for Kubernetes API Server

When we changed the service CIDR range, we needed to reissue certs used by Kubernetes API Servers. The new certs would need to include the ClusterIP address of the `kubernetes.default.svc.cluster.local`  from the new Service CIDR range. However, to generate those certs we would need to know ahead of time which IP from the new CIDR block would be assigned to the Kubernetes service. So, our migration utility ensured that Kube API Server would get the first IP address from the configured Service CIDR range and we update code that requests certificates to follow the same logic.

# Performing the Migration

After hosting pre-mortem meetings and performing the migration back and forth several times in staging we were confident that we could proceed to production. We deemed this change to be high risk in its nature, so we need to take extra precautionary steps. We worked with our Incident Management team and requested a maintenance window to perform the migration. To further reduce potential impact, we integrated the migration utility with an internal system to look up the criticality tier of the services, so that we could perform the migration for the less critical services first, before moving on to increasingly visible services.
From a technical perspective, the migration steps were the following:

1. Rollout patched version of kube-proxy to all non-control plane nodes.
1. Lock deployment pipeline tools to prevent noise during migration.
1. Rollout patched API Servers.
1. Stop kube-controller-manager.
1. Delete Services RangeAllocation object from etcd.
1. Restart kube-controller-manager.
1. Perform migration in batches, per criticality tier.
1. Unlock deployment pipeline.
1. After migration is completed do a cleanup rollout.
1. Rollout all non-control plane nodes with a vanilla version of kube-proxy.
1. Rollout vanilla version of API Servers.
1. Perform migration cleanup and clean external IPs from old service cidr block from services.

With all preparation done, we sent out our notification to customers, adjusted our timeframes a bit to meet their needs, and blocked a few weekends to perform the rollout in production. Thanks to detailed planning and preparation, we were able to complete our migration across all production clusters without even the smallest blip in QoS for Zendesk customers. This paved the way for cross-cluster service mesh, extending Kubernetes Service IP lookups and routing across cluster boundaries at Zendesk.