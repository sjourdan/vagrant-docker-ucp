# Docker Universal Control Plane (UCP) Vagrant Demo

This is a demo of [Docker Universal Control Plane (UCP)](https://www.docker.com/universal-control-plane), as of v0.5.0 (december 2015), using Vagrant.

Requirements for this demo:

- [Vagrant](https://www.vagrantup.com/)
- [Virtualbox](https://www.virtualbox.org/)
- at least 4GB of RAM on the host
- a [Docker Hub](https://hub.docker.com/) account
- an invitation on the [DockerOrca](https://hub.docker.com/u/dockerorca/) private Docker Hub team

This demo will launch 2 machines with Ubuntu 14.04 LTS and a recent 4.2.x kernel::

- ucp-master (192.168.100.10)
- ucp-slave (192.168.100.11)

UCP main container will need to be explicitly named `ucp` on all nodes, master or slave.

UCP requires a kernel > 3.16.0 to work and a minimum of 1.5GB of RAM per node.

This vagrant setup installs a 4.2.x kernel on Ubuntu 14.04 LTS for better OverlayFS support if needed.

You can tweak a few settings in the `config.rb` file.

## Deploy UCP master

Start it with the virtualbox provider and reboot the VM to activate the new kernel:

    $ vagrant up ucp-master --provider virtualbox
    $ vagrant reload ucp-master

### Install UCP Master

You can choose to deploy the master either manually (interactive) or automatically (through environment variables accessed by Docker). I recommend a fully automatic deploy.

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

## Deploy a UCP slave

### VM Deployment

Start the slave VM, and reboot it, to boot on the new kernel.

```bash
$ vagrant up ucp-slave --provider=virtualbox
$ vagrant reload ucp-slave
```

Vagrant now displays both `ucp-master` and `ucp-slave` machines:

```bash
$ vagrant status
machine states:

ucp-master                running (virtualbox)
ucp-slave                 running (virtualbox)
```

### UCP Container Deployment

To start this container, you need to grab the SHA1 fingerprint of the UCP master.

To do so, the tool has an option (fingerprint) here to help:

```bash
$ vagrant ssh ucp-master -c "docker run --rm -it --name ucp -v /var/run/docker.sock:/var/run/docker.sock dockerorca/ucp fingerprint"
SHA1 Fingerprint=E5:A2:45:C2:8B:B8:84:16:E3:F6:24:4F:49:44:3F:91:AC:FC:66:47
```

Store the SHA1 fingerprint somewhere.

Set your Docker Hub credentials in environment variables like the ucp-master (or replace the values directly from the command line):

```bash
$ export REGISTRY_USERNAME=username
$ export REGISTRY_PASSWORD=password
$ export REGISTRY_EMAIL=email@
```

Then launch the UCP slave fully configured by joining it to the cluster, with the UCP admin credentials correctly set, the master URL and SHA1 fingerprint and the node IP adresses (192.168.100.11): 

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
  --san 192.168.100.11 \
  --host-address 192.168.100.11 \
  --fingerprint=<SHA1:CERT:FINGERPRINT>
```

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
