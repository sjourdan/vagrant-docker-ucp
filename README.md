# Docker Universal Control Plane (UCP) Vagrant Demo

This is a demo of [Docker Universal Control Plane (UCP)](https://www.docker.com/universal-control-plane), as of v0.5.0 (december 2015), using Vagrant.

Requirements for this demo:

- [Vagrant](https://www.vagrantup.com/)
- [Virtualbox](https://www.virtualbox.org/)
- at least 4GB of RAM on the host (6B to 8GB with UCP replicas)
- a [Docker Hub](https://hub.docker.com/) account
- an invitation on the [DockerOrca](https://hub.docker.com/u/dockerorca/) private Docker Hub team

This demo will launch 2 machines with Ubuntu 14.04 LTS and a recent 4.2.x kernel::

- The UCP master (Primary Controller): `ucp-master` (192.168.100.10)
- `n` UCP replicas (UCP replica node): `ucp-replica-0x` (192.168.100.5x)
- `n` UCP nodes: `ucp-node-0x` (192.168.100.10x)

Optionally, you can launch two (or more) replicas:

- ucp-replica-01 (192.168.100.51)
- ucp-replica-02 (192.168.100.52)

| role        | hostname        | IP              |
|-------------| --------------- |-----------------|
| UCP Master  | ucp-master      | 192.168.100.10  |
| UCP Replica | ucp-replica-0x  | 192.168.100.5x  |
| UCP Node    | ucp-node-0x     | 192.168.100.10x |

UCP main container will need to be explicitly named `ucp` on all nodes, master or node (`--name ucp`).

UCP requires a kernel > 3.16.0 to work and a minimum of 1.5GB of RAM per node.

This vagrant setup installs a 4.2.x kernel on Ubuntu 14.04 LTS for better OverlayFS support if needed.

You can tweak a few settings in the `config.rb` file.

## Deploy UCP master

Start it with the virtualbox provider and reboot the VM to activate the new kernel:

    $ vagrant up ucp-master --provider virtualbox
    $ vagrant reload ucp-master

### Install UCP Master

You can choose to deploy the master either manually (interactive) or automatically (through environment variables accessed by Docker). I recommend a fully automatic deploy.

Access the master VM by issuing:

```bash
$ vagrant ssh ucp-master
```

#### Interactive Deploy

Bootstrap interactively the system, that will ask some questions:

- Docker Hub username, password and email
- UCP admin password (`admin:orca` by default)

```bash
$ docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --name ucp dockerorca/ucp install -i
INFO[0000] Verifying your system is compatible with UCP
Please choose your initial Orca admin password:
Confirm your initial password:
INFO[0011] Pulling required images
```

#### Automated Deployment

Export or set a few environment variables about your Docker Hub account:

```bash
export REGISTRY_USERNAME=username
export REGISTRY_PASSWORD=password
export REGISTRY_EMAIL=email@
```

Then launch the container fully configured with the ucp name, as a fresh-install, and specifying our IP adress 192.168.100.10:

```bash
$ docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e REGISTRY_USERNAME=${REGISTRY_USERNAME} \
  -e REGISTRY_PASSWORD=${REGISTRY_PASSWORD} \
  -e REGISTRY_EMAIL=${REGISTRY_EMAIL} \
  --name ucp \
  dockerorca/ucp install \
  --fresh-install \
  --san 192.168.100.10 \
  --host-address 192.168.100.10
```

UCP will then be available at https://192.168.100.10 with credentials: `admin:orca`.

## Deploy UCP nodes

A UCP node is a UCP machine on which the swarm cluster can launch containers.

The amount of nodes is set by the `$ucp_nodes_number` value under `config.rb` (ie.: a value of 3 will launch 3 nodes named `ucp-node-01`, `ucp-node-02` and `ucp-node-03`).

### VM Deployment

Start the UCP node VM, and reboot it, to boot on the new kernel.

```bash
$ vagrant up ucp-node-01 --provider=virtualbox
$ vagrant reload ucp-node-01
```

Vagrant now displays both `ucp-master` and `ucp-node` machines:

```bash
$ vagrant status
machine states:

ucp-master                running (virtualbox)
ucp-node-01                 running (virtualbox)
[...]
```

Access the node VM by issuing:

```bash
$ vagrant ssh ucp-node-01
```

### UCP Node Container Deployment

To start this container, you need to grab the SHA1 fingerprint of the UCP master.

To do so, the tool has an option (fingerprint) here to help:

```bash
$ vagrant ssh ucp-master -c "docker run --rm -it --name ucp -v /var/run/docker.sock:/var/run/docker.sock dockerorca/ucp fingerprint"
SHA1 Fingerprint=E5:A2:45:C2:8B:B8:84:16:E3:F6:24:4F:49:44:3F:91:AC:FC:66:47
```

Store the SHA1 fingerprint somewhere, like:

```bash
export UCP_MASTER_SHA=E5:A2:45:C2:8B:B8:84:16:E3:F6:24:4F:49:44:3F:91:AC:FC:66:47
```

Set your Docker Hub credentials in environment variables like the ucp-master (or replace the values directly from the command line):

```bash
$ export REGISTRY_USERNAME=username
$ export REGISTRY_PASSWORD=password
$ export REGISTRY_EMAIL=email@
```

Then launch the UCP node fully configured by joining it to the cluster, with the UCP admin credentials correctly set, the master URL and SHA1 fingerprint and the node IP adresses (ie.:192.168.100.101):

```bash
$ docker run --rm -it \
  --name ucp \
  -e UCP_ADMIN_USER=admin \
  -e UCP_ADMIN_PASSWORD=orca \
  -e REGISTRY_USERNAME=${REGISTRY_USERNAME} \
  -e REGISTRY_PASSWORD=${REGISTRY_PASSWORD} \
  -e REGISTRY_EMAIL=${REGISTRY_EMAIL} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  dockerorca/ucp join \
  --url https://192.168.100.10:443 \
  --san 192.168.100.101 \
  --host-address 192.168.100.101 \
  --fingerprint=${UCP_MASTER_SHA}
```

## High-Availability UCP (replicas)

Optionally launch replicas to the cluster. A replica is a node that can behave like a UCP controller, if the master controller fails. Ideally, all controllers (master and replicas) are behind a load balancer, accessed by a single IP.

### VM Deployment

Start 2 replica VMs, and reboot them to boot on the new kernel.

```bash
$ vagrant up ucp-replica-01 ucp-replica-02 --provider=virtualbox
$ vagrant reload ucp-replica-01 ucp-replica-02
```

Access the replica VM by issuing:

```bash
$ vagrant ssh ucp-replica-01
$ vagrant ssh ucp-replica-02
```

### UCP Replica Container Deployment

To start this container, you need to grab the SHA1 fingerprint of the UCP master and basically add the `--replica` option to the container.

To do so, the tool has an option (fingerprint) here to help:

```bash
$ vagrant ssh ucp-master -c "docker run --rm -it --name ucp -v /var/run/docker.sock:/var/run/docker.sock dockerorca/ucp fingerprint"
SHA1 Fingerprint=E5:A2:45:C2:8B:B8:84:16:E3:F6:24:4F:49:44:3F:91:AC:FC:66:47
```

Store the SHA1 fingerprint somewhere, like:

```bash
export UCP_MASTER_SHA=E5:A2:45:C2:8B:B8:84:16:E3:F6:24:4F:49:44:3F:91:AC:FC:66:47
```

Set your Docker Hub credentials in environment variables like the ucp-master (or replace the values directly from the command line):

```bash
$ export REGISTRY_USERNAME=username
$ export REGISTRY_PASSWORD=password
$ export REGISTRY_EMAIL=email@
```

Then launch the UCP replica fully configured by joining it to the cluster, with the UCP admin credentials correctly set, the master URL and SHA1 fingerprint and the node IP adresses (192.168.100.52):

```bash
$ docker run --rm -it \
  --name ucp \
  -e UCP_ADMIN_USER=admin \
  -e UCP_ADMIN_PASSWORD=orca \
  -e REGISTRY_USERNAME=${REGISTRY_USERNAME} \
  -e REGISTRY_PASSWORD=${REGISTRY_PASSWORD} \
  -e REGISTRY_EMAIL=${REGISTRY_EMAIL} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  dockerorca/ucp join \
  --url https://192.168.100.10:443 \
  --san 192.168.100.52 \
  --host-address 192.168.100.52 \
  --fingerprint=${UCP_MASTER_SHA} \
  --replica
```

All master replicas now show up on the dashboard at https://192.168.100.10

## Application Deployment

### Setup

To use the Docker-Compose "Application" feature, you need to first download a "bundle".

- Login with your user to https://192.168.100.10
- Navigate to your profile (https://192.168.100.10/#/user)
- Generate a "Client Bundle" by clicking "Create a Client Bundle", and/or download your "bundle" (a `ucp-bundle-$username.zip` file)
- Then import it on your workstation to use it:

```bash
cd bundle
unzip ucp-bundle-admin.zip
eval $(<env.sh)
```

Verify it's talking to the cluster:

```bash
$ docker info
Containers: 11
Images: 18
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 2
[...]
```

### Single-Container Demo: Ghost Blog

Just use the regular docker-compose!

```bash
cd blog
docker-compose up -d
```

To know where it's running, use `docker ps` and read the `PORTS` column, or use the UCP GUI.

Ghost will then be available at [http://192.168.100.11:2368](http://192.168.100.11:2368).
