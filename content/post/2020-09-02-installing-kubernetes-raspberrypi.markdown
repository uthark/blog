---
title: "Installing Kubernetes on Raspberry Pi"
date: 2020-09-02T20:44:30-07:00
draft: false
categories:
- kubernetes
- raspberrypi
tags:
- kubernetes
- raspberrypi
- arm64
- kubeadm
- docker
- cgroups
---

Installing kubernetes on Raspberry Pi is easy, but there are few caveats that you need to be aware of.

`arm64` is preferred, because 64-bit allows you to use > 4GB of RAM per process.

## Enable cgroups
Kubernetes relies on cgroups for enforcing limits for the containers, so kernel needs to be booted with cgroups support.
On Raspberry, edit `/boot/firmware/cmdline.txt` and add the following options:

```
cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
```
Reboot after making the changes.
```
sudo shutdown -r now
```

## Install and configure docker

Allow to use HTTPS transport for downloading packages:
```
sudo apt update
sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
```

Add docker GPG key used for verifying `Packages` file used by apt.
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

Add docker repository:
```
echo "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
```

Update apt repository index and install docker

```
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
```

If you want to communicate with docker with non-root user:

```
sudo usermod -aG docker "your user"
```

To apply changes - logout and login again. If you want to reflect changes immediately run:

```
newgrp docker
```

Configure docker to use systemd as a cgroups driver, put in `/etc/docker/daemon.json`:

```
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}

```

## Installing kubeadm

Add kubernetes repository:
```
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

To allow iptables properly work with bridged traffic:
```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```

Install kubeadm, kubelet and kubectl:
```
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
```

Minor updates of kubernetes may require extra steps, so we need to prevent packages from auto-updating:

```
sudo apt-mark hold kubelet kubeadm kubectl
```

## Installing Kubernetes Control Plane

Generate token for installation
```
TOKEN=$(sudo kubeadm token generate)
```

Install control plane with kubeadm:

```
sudo kubeadm init --token=${TOKEN} --kubernetes-version=v1.19.0
```

If installation is successful, output will look similar to this:

```
W0903 00:29:04.934934  417169 configset.go:348] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
[init] Using Kubernetes version: v1.19.0
[preflight] Running pre-flight checks
	[WARNING SystemVerification]: missing optional cgroups: hugetlb
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local ubuntu] and IPs [10.96.0.1 192.168.1.153]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost ubuntu] and IPs [192.168.1.153 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost ubuntu] and IPs [192.168.1.153 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 30.007706 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.19" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node ubuntu as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node ubuntu as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: 5p4y2w.xxivtzh1lvuukdk7
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.153:6443 --token 5p4y2w.xxivtzh1lvuukdk7 \
    --discovery-token-ca-cert-hash sha256:5638c83bec2b62b5f01d85bc2f4330b03b7e3c4682fe3f5e7e4189fbb63c5a17
```

## Configure kubectl to communicate with the cluster

Put kubeconfig file in user's home directory:

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

```

Verify it works:

```
kubectl get nodes
```

In my case output was:

```
NAME     STATUS   ROLES    AGE     VERSION
ubuntu   Ready    master   3h42m   v1.19.0

```

As a CNI network provider I use Calico, but you can use any you like. [List of available implementations](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model)

```
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml
```

Now you have working single node kubernetes cluster. Next things you might need to do:
1. Add worker nodes: use `kubeadm join`.
2. Install [MetalLB](https://metallb.universe.tf/) – Loadbalancer for bare-metal kubernetes clusters
3. Install [Helm](https://helm.sh/) to install kubernetes packages.
4. If you have only single raspberry pi, you need to remove taint from your control plane node so that it regular workload can be scheduled on it:
   ```
   kubectl taint nodes --all node-role.kubernetes.io/master-
   ```

## References
* [Docker Installation](https://docs.docker.com/engine/install/ubuntu/)
* [Bootstrapping clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
* [Kubernetes Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model)