---
title: "Running Pi-hole on Kubernetes"
date: 2021-10-06T21:36:07-07:00
draft: false
categories:
- kubernetes
- pihole
tags:
- kubernetes
- pihole
---

Recently I wrote how you can [install Kubernetes on Raspberry Pi](/post/2020-09-02-installing-kubernetes-raspberrypi/). 

In this post we will install Pi-Hole on Kubernetes.

Up to recent versions of Pi-Hole Docker images you had to take care of the correct architecture (and as a result correct docker tag to use).

Now they use multiarch docker image, so you can use docker image `pihole/pihole:<version>` which will work both on `amd64` and `arm` architectures.

We will use Kubelet's ability to run [static pods].

We need to create 2 folders on the host, these folders would keep Pi-Hole data.

```bash
mkdir -p /data/pihole/{etc,dnsmasq.d}
chmod go+r /data/pihole/{etc,dnsmasq.d}
```

Copy the manifest and make the following changes:

1. Set your timezone (`TZ`)
2. Set your password to login to pihole web UI (`WEBPASSWORD`)
3. Update the tag of the [pihole/pihole][pihole-docker] docker image
and save it as `pihole.yaml` in `/etc/kubernetes/manifests`

Complete manifest:

{{< gist uthark 1fbf0f93ff8eed075e0bf6901ffef1ed >}}

[static pods]: <https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/>
[pihole-docker]: <https://hub.docker.com/r/pihole/pihole/tags>
