# vagrant-kubernetes
A Kubernetes cluster on vagrant

## Prerequisites

1. vagrant
1. VirtualBox
1. ansible

## Set up

1. Clone the repository - `git clone https://github.com/plenderyou/vagrant-kubernetes.git`
2. Go to the cloned directory
3. Create a customise.rb file based on the customise.rb.sample
4. Make sure you have the vagrant box installed: `vagrant box add ubuntu/xenial64`
4. `vagrant up` - this can take some time

## What happend?

### All nodes

* 1 master and the nodes were created for the cluster
* There is a localhost network created so the nodes can communicate with each other
  * IP_BASE + 10 for master
  * IP_BASE + 11 for node 1
  * etc.
* Your local user was created on each machine with sudo rights and using your id_rsa.pub key for ssh
* The hosts file on each machine has an entry for all the other machines (This is important as it does not set up dns)
* the kubernetes repo was added to each machine
* the following was installed on each machine
  * docker.io
  * kubelet
  * kubeadm
  * kubectl
  * kubernetes-cni
  * jq
* the hostname-override setting was added to the kubelet service

### Master

* kubeadm init --api-advertise-address=<IP ADDRESS> was run and the output was sent /vagrant/kubeinit so it's available to other nodes
* the advertise-address was added to the kube-apiserver
* The kube-proxy was modified to use --proxy-mode=userspace (This may not be required in future)
* The weave-kube network was added to the kubernetes cluster
* The admin.conf file was copied to the vagrant directory (this allows kubectl to be run from the host easily)


At this point if all has gone well you should have a working cluster

If you log into the master: `ansible ssh master`
and run `kubectl get pods --all-namespaces -o wide` you should see something like:

```
NAMESPACE     NAME                                READY     STATUS    RESTARTS   AGE       IP             NODE
kube-system   etcd-jp-master                      1/1       Running   0          4m        172.16.99.10   jp-master
kube-system   kube-apiserver-jp-master            1/1       Running   3          4m        172.16.99.10   jp-master
kube-system   kube-controller-manager-jp-master   1/1       Running   0          4m        172.16.99.10   jp-master
kube-system   kube-discovery-982812725-hhl53      1/1       Running   0          5m        172.16.99.10   jp-master
kube-system   kube-dns-2247936740-66hde           3/3       Running   0          5m        10.32.0.2      jp-master
kube-system   kube-proxy-amd64-6tfhw              1/1       Running   0          4m        172.16.99.11   jp-node-1
kube-system   kube-proxy-amd64-99kp3              1/1       Running   0          4m        172.16.99.13   jp-node-3
kube-system   kube-proxy-amd64-9lh4o              1/1       Running   0          4m        172.16.99.12   jp-node-2
kube-system   kube-proxy-amd64-a4jwq              1/1       Running   0          4m        172.16.99.10   jp-master
kube-system   kube-scheduler-jp-master            1/1       Running   0          5m        172.16.99.10   jp-master
kube-system   weave-net-2vrza                     2/2       Running   0          5m        172.16.99.10   jp-master
kube-system   weave-net-tl07r                     2/2       Running   0          4m        172.16.99.12   jp-node-2
kube-system   weave-net-u25cs                     2/2       Running   1          4m        172.16.99.13   jp-node-3
kube-system   weave-net-vwm9e                     2/2       Running   1          4m        172.16.99.11   jp-node-1
```
It may take a while for all pods to start.

### nodes

Each node is registered with the cluster.

## Using the cluster

You can log onto the master or any node to use the cluster. All scripts are available in the `/vagrant` directory

## Setup kubectl to run from your host

Optionally, you can follow the instructions [here ](http://kubernetes.io/docs/user-guide/prereqs/) to install kubectl in your local host.

Now use the `admin.conf` as the kube config

``` shell
export KUBECONFIG=$PWD/admin.conf
```

And for listing the current pods from your local host:

``` shell
kubectl get pod --all-namespaces
```

## Installing the kubernetes dashboard

``` shell
curl https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml \
  | awk '{print $0} /targetPort:/ { printf("    nodePort: 32100\n", $0) }' \
  | kubectl create -f -

```

hitting any node on port [32100](http://172.16.99.10:32100/) with the browser should bring up the dashboard.

## Using docker in the cluster

If you wish to build images on the cluster hosts you need to have a docker registry, the scripts for this are in the `extras/registry` sub-directory

``` shell
kubectl create -f registry.yml
kubectl create -f registry-service.yml
```

This will make the registry available on the `localhost:32000` on each node

You can now go onto the master or node and run docker if the user is a member of the docker group.

## The hello-world sample

The hello world sample is a simple node server that prints out the headers and the hostname

Go to the `/vagrant/extras/hello-world` directory

### Build that docker images
``` shell
docker build -t localhost:32000/hello-world:v1 .
docker push localhost:32000/hello-world:v1
```

### Deploy the replication controller

``` shell
kubectl create -f hello-world-rc.yml
```

Now find out where it's Running

``` shell
kubectl get pod -l "app=hello-world" -o wide
```

and curl one of the ip addresses on port 8080

### Access from the outside world

We're going to create and ingress point from the outside world using an ingress controller.
**N.B. There are some limitations with this at the moment as the CNI network does not support hostPort definitions**

Go to the `/vagrant/extras/ingress` directory and create the ingress replication controller

``` shell
kubectl create -f nginx-ingress-rc.yml
```
**This should have exposed port 80 on the host as the access point for the ingress controller, however this does not work on this type of cluster (Known issue)**


Now go back to the hello-world directory and create a headless service and an ingress

```shell
kubectl create -f hello-world-svc.yml
kubectl create -f hello-world-ingress.yml
```

the ingress point should set up a name-based virtual host on the **nginx server** for host 'hello-world'

Find out the ip address if the ingress controller using kubectl (or the dashboard)
```shell
kubectl get pod -o wide -l "app=nginx-ingress" | awk '/ingress/ {print $6}'
```

Then curl this ip overriding the resolve on curl.
```shell
 curl --resolve hello-world:80:<IP_ADDRESS> http://hello-world
```

Calling this multiple times will show that the loadbalancing is working.

### Work around for lack of hostPort functionality

I haven't spent a lot of time looking for solutions to the ingress issue, however there are a number of alternatives that should be explored

1. Use `iptables` to forward the traffic on the hosts port 80 to the ingress controller (this should probably use a secondary ip address)
2. Use a proxy on a host to forward the traffic to the ingress controller.

Option 2 is the simplest in the ingress directory there is a script called balance.sh that uses the balance loadbalancer to forward traffic.
This requires balance to be installed on the machine you choose `apt-get install balance`

Then you can use a similar curl command from your host machine replacing the ip address with the machines ip address.
