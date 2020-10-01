---
title: "Causes of UnexpectedAdmissionError in Kubernetes"
date: 2020-10-01T00:00:29-07:00
draft: false
toc: false
comments: false
categories:
- kubernetes
tags:
- unexpectedadmissionerror
- kubernetes
---

Recently I found that sometimes kubernetes pods are not starting. They were failing
with enigmatic `UnexpectedAdmissionError`. Time to deep dive into what may cause it.

After searching through the [kubernetes codebase](https://github.com/kubernetes/kubernetes)
I found several places where this status was set.

<!--more-->

As of Kubernetes 1.19, this error will be set in the following cases:

1. [CPU](https://kubernetes.io/blog/2018/07/24/feature-highlight-cpu-manager/)
[Manager](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/) can’t admit the pod.
1. [Device Manager](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/) can’t admit the pod.
1. [Topology](https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/)
 [Manager](https://kubernetes.io/blog/2020/04/01/kubernetes-1-18-feature-topoloy-manager-beta/)
  can’t admit the pod.
1. Unable to provision [extended resource](https://kubernetes.io/docs/tasks/administer-cluster/extended-resource-node/)
1. Plugin Resource failure.
1. Pod can't be admitted due to unknown reason.

In my particular case it was caused by CPU Manager - there were CPU and Memory to 
admit the pod, but it was not possible to give the pods exclusive number of CPUs.
