---
title: "Notes on FailedPreStopHook in Kubernetes"
date: 2022-02-11T19:09:42-08:00
draft: true
toc: false
comments: false
categories:
- kubernetes
- 
tags:
- kubernetes
- failedprestophook
---

Recently I was debugging an issue with `FailedPreStopHook` in kubernetes. This was an exciting issue to troubleshoot and fix.  

<!--more-->

The application is a critical part of our software stack, and we are pretty sensitive if it doesn't work as expected.

The original request was about something wrong with the underlying platform because the app seemed innocent, and the `preStop` hook was also a simple script that didn’t have obvious issues.

PreStop hook error failure contained error code 137, which indicates that the application was terminated due to being out of memory. This was weird because we didn’t see any spikes in memory usage by the app.

1. FailedPreStopHook
2. ExecSync error
3. Checking times
4. Checking manifests

We found out that the cause of the `FailedPreStopHook` was an incorrect `preStop` hook which took much more time to finish than the main container. This caused kubelet to terminate the container and generate the Event that the monitor picked up.
