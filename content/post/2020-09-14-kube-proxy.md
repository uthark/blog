---
title: Kube Proxy Deep Dive
date: 2020-09-13T22:56:04-07:00
draft: true
toc: true
comments: true
categories:
- kubernetes
- kube-proxy
tags:
- kubernetes
- kube-proxy
- overview
---

Kubernetes Control Plane consists of several components. In this post I would like to go deeper into `kube-proxy`, why it’s needed, how does it work and what features does it provide for the end user.
<!--more-->

## Overview
Kube Proxy is kubernetes network proxy which runs on each node of the cluster.
When `Service` of type `ClusterIP` is created, it get assigned IP Address. This IP Address is from `--service-cluster-ip-range` configured in Kubernetes API Server.

## Installation
kube-proxy can be work either as a host service (i.e. as a systemd unit) or as a `DaemonSet`. Other option is to start it as a static pod, it depends on your installation.

## How does it work?
kube-proxy has three mode of operation:
1. Userspace
2. iptables
3. ipvs. 

They are slightly different and [documentation outlines][kube—proxy-overview] differences between modes.


 
## References
- [kube-proxy command line reference][cli-ref]
- [kube-proxy Operating Modes][kube—proxy-overview]

[cli-ref]: <https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/>
[kube—proxy-overview]: <https://kubernetes.io/docs/concepts/services-networking/service/#ips-and-vips>