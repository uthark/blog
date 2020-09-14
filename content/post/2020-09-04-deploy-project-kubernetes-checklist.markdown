---
title: "Deploying in Kubernetes. Checklist."
date: 2020-09-04T15:08:37-07:00
draft: false
categories:
- kubernetes
- bestpractices
- development
tags:
- kubernetes
- bestpractices
- checklist
---

While kubernetes is easy to start with, it is quite challenging to master and
 know all details. In this post I will provide checklist of important manifest 
 stanzas that are applicable to most applications that are targeted to run in
 production and which are expected to not have downtime during cluster 
 maintenance and/or application updates.

<!--more-->
 
Deploying to kubernetes is easy: create manifest with your `Deployment` and then `kubectl apply` it.

The most basic deployment manifest looks like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: test-app
  name: test-app
  namespace: default
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: test-app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: test-app
    spec:
      containers:
      - name: controller
        image: nginx
```

It works as is, but you may improve reliability of this deployment by configuring additional fields for the manifest.

## Metadata
Use `metadata` field efficiently. You can add labels who owns the deployment, if they are part of the bigger project, and so on.
This will allow to discover all deployments that are owned by a specific department:

```
kubectl get deploy -n production -l department=marketing
```

## CPU/Memory Requests/Resources
Correct configuration is important. Requests are used for scheduling (kubelet reports node configuration to scheduler and scheduler uses this information when decides where the pod will be assigned). Limits are used for enforcing usage in runtime.

### Things to remember:
1. If you go over memory limit, app will be OOMKilled.
2. If you go over CPU limit, app will be throttled. In fact this is more complicated and your app may be throttled before reaching limit, but this is a topic for another post.
3. The configuration set affects [Quality of Service][qos] for pod.
4. QoS affects what happens with your pod when kubelet on the node is [out of resources][outofresources]

## Do not use `latest` tag in images
I [spoke about it previously]({{< ref "/post/2020-09-03-docker-best-practices" >}}). Use exact version, i.e. `nginx:1.19.2`. This is better than `latest`, but even better to use sha256 of the image: 

```
image: nginx@sha256:9d660d69e53c286fbdd472122b4b583a46e8a27f10515e415d2578f8478b9aad
```

## Update Strategy

Default strategy is `RollingUpdate`. If you run multiple replicas of the application, consider tuning `maxUnavailable`/`maxSurge` based on your requirements.
If your app have multiple replicas and each replica requires a lot of CPU/Memory, having `maxSurge` might require autoscaler to provision extra nodes.

## Service Accounts
By default, each deployment will use `default` service account. If app requires access to kubernetes API, consider creating separate service account for the app. This will allow improve your isolation and security:
1. Use [PodSecurityPolicy][psp] for fine-grained authorization of what’s allowed to pod to do on the node. 
2. Use [RBAC ClusterRoleBinding/RoleBinding][rbac] to control permissions for the resources in Kubernetes.

## SecurityContext
`securityContext` allows to control security context of the pod. Recommended to enforce `runAsNonRoot`. [See documentation][securitycontext]

## Pod Disruption Budget
If you have multiple replicas of the application, create `PodDisruptionBudget` for the `Deployment`. See [documentation][pdb] for more details.

## Liveness & Readiness Probes
I cannot stress more importance of it. I’ve seen application being taken down when they should not and vice versa. Your biggest nightmare will be if you do a rollout when new pods are crashlooping and olds pods are not terminated when they should. 

## Lifecycle Hook - Post Start / Pre Stop
Lifecycle hooks allows gracefully terminate application. I.e. you can finish current request, save state and then terminate. See [documentation][lifecyclehooks]

## Priority Classes
Not all apps are created equal. Some apps are more important. Consider defining priority classes and use appropriate priority class for the application. [Read more in official documentation][ppp]

## Taints and tolerations
Sometimes there are specific requirements where application should or should not run.
Taints allows to taint nodes to prevent regular workload from scheduling on those node. To allow workload to be scheduled on the nodes - use Tolerations.
[See documentation][taintstolerations]

## Affinities and anti-affinities
Affinities and anti-affinities provides you more control where to schedule the workload. For example, you might want to use pod anti-affinity to distribute replicas of the application across different nodes or availability zones. See [documentation][scheduling] for details.
Another great feature that you might need is [Topology Manager][topology] for better allocation of the workload.

## References
This is a must read documentation to learn / refresh your knowledge: 

* [Workload - Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
* [Workload – Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
* [Container Lifecycle Hooks][lifecyclehooks]
* [Workload – Pod Lifecycle][podlifecycle]
* [Pod Security Policies][psp]
* [Configure a Security Context for a Pod or Container][securitycontext]
* [Specifying a Disruption Budget for your Application][pdb]
* [Configure Liveness, Readiness and Startup Probes][liveness]
* [Configure Service Accounts for Pods][serviceaccount]
* [Scheduling and Eviction – Assigning Pods to Nodes][scheduling]
* [Assign CPU Resources to Containers and Pods][assign-cpu-resource]
* [Assign Memory Resources to Containers and Pods][assign-memory-resource]
* [Configure Out of Resource Handling][outofresources]
* [Topology Manager][topology]
* [Using RBAC Authorization][rbac]
* [Pod Priority and Preemption][ppp]
* [Configure Quality of Service for Pods][qos]
* [apps/v1 Deployment API Reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deployment-v1-apps)
* [core/v1 PodSpec API Reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#podspec-v1-core)

[pdb]: <https://kubernetes.io/docs/tasks/run-application/configure-pdb/>
[ppp]: <https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/> (Pod Priority and Preemption)
[podlifecycle]: <https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/>
[liveness]: <https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/>
[lifecyclehooks]: <https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/>
[taintstolerations]: <https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/>
[scheduling]: <https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/>
[topology]: <https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/>
[assign-memory-resource]: <https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/>
[assign-cpu-resource]: <https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/>
[qos]: <https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/>
[outofresources]: <https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/#best-practices>
[securitycontext]: <https://kubernetes.io/docs/tasks/configure-pod-container/security-context/>
[serviceaccount]: <https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/>
[psp]: <https://kubernetes.io/docs/concepts/policy/pod-security-policy/>
[rbac]: <https://kubernetes.io/docs/reference/access-authn-authz/rbac/>
