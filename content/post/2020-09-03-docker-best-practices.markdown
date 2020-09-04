---
title: "Docker Best Practices"
date: 2020-09-03T22:05:41-07:00
draft: false
categories:
- bestpractices
- docker
- development
tags:
- docker
- bestpractices
---

## Introduction 

After using docker for last several years I’d like to share best practices that works in production.

## Reduce container image size
In Cloud Native world infrastructure is disposable and immutable. As result, if your kubernetes pod is rescheduled to another node, new node need to pull docker image.

Small docker images provide the following benefits:

1. Smaller attack surface. If image contain only your app binaries and direct dependencies without full blown OS, you will need to apply patches to fix vulnerabilities infrequently. 
2. Faster application startup. Your container runtime will download image faster.
3. Less network utilization. You will reduce your network bandwidth utilization.
4. Less cost. Smaller images take less space. In modern cloud days you pay for the storage, using less space saves you money.

### How?
There are several techniques to reduce image size:

1. Use [distroless](https://github.com/GoogleContainerTools/distroless) base images. "Distroless" images contain only your application and its runtime dependencies. They do not contain package managers, shells or any other programs you would expect to find in a standard Linux distribution.
2. If you need basic shell, try to use [busybox](https://hub.docker.com/_/busybox) or try using [alpine](https://hub.docker.com/_/alpine) – this is minimalistic linux distribution. One caveat is that you might need to pass extra flags for app during compilation to make it compatible with alpine.
3. [Use multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/). This will allow you to build image in one container and the copy resulting binaries in a final image that doesn’t have compiler tools, source code and other data. Using multistage builds allows you to not use all commands in a single `RUN` stanza in `Dockerfile`, which improves source code readability

## Security is important
Principle of least privilege should be used as much as possible. Within its cgroup docker container runs as root. If there is a new kernel vulnerability, malicious container might try to use it and escape to the host using 	`root` permissions.

### How?
1. Set `USER` in the `Dockerfile`.
2. Do not use `latest` in `FROM`. If you use `latest`, you will pull latest base image. Downsides of it are the following:

	1. If upstream repository is compromised, you might get compromised image with `latest`
	2. If upstream repository bumps version, you might get incompatible version of the software in your image. Dependency updates should be manageable and not happen ad hoc.
 
3. Use digest/`@sha256` in `FROM` to specify exact version of the container you’re pulling. Digest is shown on tag page on docker hub or you can get it after running `docker pull`:

			 ```
			 $ docker pull alpine:3.12.0
			 3.12.0: Pulling from library/alpine
			 df20fa9351a1: Pull complete
			 Digest: sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321
			 Status: Downloaded newer image for alpine:3.12.0
			 docker.io/library/alpine:3.12.0
			 ```

		`Dockerfile` will looks like this:
		
		```
		FROM alpine@sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321
		COPY ...
		# And so on.
		``` 
		
	4. Use own docker registry. Rebuild all required base images yourself and use them. This will allow you to control which base image are being used.
	5. Prohibit running docker containers from `docker.io` in production. If you run in kubernetes, use [Open Policy Agent Gatekeeper](https://github.com/open-policy-agent/gatekeeper) or similar solution. docker.io contains a lot of images that are build both by well-known companies and by random people, not all of them have good intentions.

## Improve maintainability
1. Add [`LABEL`](https://docs.docker.com/engine/reference/builder/#label) with information about image maintainer and other information that is relevant for your organization.
2. Use [`ARG`](https://docs.docker.com/engine/reference/builder/#arg) to pass base IMAGE. This will allow you to configure base image outside and give you ability to manage base image at scale if you have large organization/have hundreds of different images.
