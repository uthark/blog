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

In this post, we will install Pi-Hole on Kubernetes.

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


```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pihole
#  namespace: pihole
spec:
  hostNetwork: true
  dnsPolicy: "None"
  dnsConfig:
    nameservers:
      - 1.1.1.1
  containers:
    - name: pihole
      image: pihole/pihole:2021.10
      imagePullPolicy: IfNotPresent
      env:
        - name: TZ
          value: "America/Los_Angeles"
        - name: WEBPASSWORD
          value: <CUSTOMIZE>
      securityContext:
        privileged: true
      ports:
        - containerPort: 53
          protocol: TCP
        - containerPort: 53
          protocol: UDP
        - containerPort: 67
          protocol: UDP
        - containerPort: 80
          protocol: TCP
        - containerPort: 443
          protocol: TCP
      volumeMounts:
        - name: etc
          mountPath: /etc/pihole
        - name: dnsmasq
          mountPath: /etc/dnsmasq.d
      resources:
        requests:
          memory: 128Mi
          cpu: 100m
        limits:
          memory: 2Gi
          cpu: 1
  volumes:
    - name: etc
      hostPath:
        path: /data/pihole/etc
      type: Directory
    - name: dnsmasq
      hostPath:
        path: /data/pihole/dnsmasq.d
      type: Directory
```

[static pods]: <https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/>
[pihole-docker]: <https://hub.docker.com/r/pihole/pihole/tags>
