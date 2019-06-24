# Managing a Graphistry Deployment

Welcome to Graphistry! Graphistry command-line administration is via standard docker-compose `.yml` / `.env` files and `nginx` configuration.

The `graphistry-cli` repository contains 
* Optional reference scripts to setup cloud Linux environment dependencies for Graphistry from scratch
* Documentation for operating the Graphistry Docker container (install, configure, start/stop, & debug)
* Documentation for configuring the software: `nginx`, connectors, and ontology

## Quick start

The fast install is to lauch the AWS Marketplace AMI, which turns on and runs with zero additional configuration necessary.

## Manual install for Nvidia environments, including AWS

**Launch & Configure Nvidia for Docker**
[AWS Nvidia Ubuntu Deep Learning AMIs](https://aws.amazon.com/marketplace/seller-profile?id=c568fe05-e33b-411c-b0ab-047218431da9&ref=dtl_B076K31M1S) have everything except you need to enable the default docker runtime:

```
############ Environment
$ docker info | grep Default    ### => runc
$ sudo vim /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
$ sudo systemctl restart docker ### without, may need `docker system prune -a && docker system prune --volumes`
$ docker info | grep Default    ### => nvidia
```

**Install Graphistry container**

```
############ Install & Launch
wget -O release.tar.gz "https://..."
tar -xvvf release.tar.gz
docker load -i containers.tar
docker-compose up -d
```

## Quick Commands

|  	|  	|  	|
|--: |---	|---	|
| **Install** 	| `docker load -i containers.tar` 	| Install the `containers.tar` Graphistry release from the current folder. You may need to first run `tar -xvvf my-graphistry-release.tar.gz`.	|
| **Start (interactive)** 	| `docker-compose up` 	| Starts Graphistry, close with ctrl-c 	|
| **Start (daemon)** 	| `docker-compose up -d` 	| Starts Graphistry as background process 	|
| **Stop** 	| `docker-compose stop` 	| Stops Graphistry 	|
| **Restart** 	| `docker restart <CONTAINER>` 	|  	|
|  **Status** 	| `docker-compose ps`, `docker ps`, and `docker status` 	|  	|
|  **API Key** 	| docker-compose exec streamgl-vgraph-etl curl "http://0.0.0.0:8080/api/internal/provision?text=MYUSERNAME" 	|  Generates API key for a developer or notebook user	|
| **Logs** 	|  `docker logs <CONTAINER>` (or `docker exec -it <CONTAINER>` followed by `cd /var/log`) 	|  	|


## Contents

* Instance & Environment Setup
   1. Prerequisites
   2. Instance Provisioning
     * AWS
     * Azure
     * On-Premises
     * Airgapped
   3. Linux Dependency Installation
   4. Graphistry Container Installation
   5. Start!
* Configuration
* Maintenance
  * OS Restarts 
  * Upgrading
* Testing
* Troubleshooting


# Instance & Environment Setup


## 1. Prerequisites

* AWS Marketplace: Quota for GPU (P3.2+) in your region; ignore everything else below
* Graphistry Docker container
* Linux with `nvidia-docker-2`, `docker-compose`, and `CUDA 9.2`. Ubuntu 16.04 cloud users can use a Graphistry provided environment bootstrapping script.
* NVidia GPU: K80 or later. Recommended G3+ on AWS and NC Series on Azure.
* Browser with Chrome or Firefox

For further information, see [Recommended Deployment Configurations: Client, Server Software, Server Hardware](https://github.com/graphistry/graphistry-cli/blob/master/docs/hardware-software.md).

## 2. Instance Provisioning


### AWS Marketplace (Recommended)

* Use any of the recommended instance types: P3.2+

### AWS BYOL - From a new Nvidia AMI
* Launch a base Nvidia Deep Learning Ubuntu AMI on a `p3.*` 
* Use S3AllAccess permissions, and override default parameters for: 200GB disk
* Enable SSH/HTTP/HTTPS in the security groups
* SSH as ``ubuntu@[your ami]``
* Set `nvidia` as the default docker run-time: 
```
$ docker info | grep Default    ### => runc
$ sudo vim /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
$ sudo systemctl restart docker ### without, may need `docker system prune -a && docker system prune --volumes`
$ docker info | grep Default    ### => nvidia
```
* Follow `docker load` instructions up top.


### AWS BYOL - From a base Linux AMI
* Launch an official AWS Ubuntu 16.04 LTS AMI using a ``g3+``or ``p*`` GPU instance. 
* Use S3AllAccess permissions, and override default parameters for: 200GB disk
* Enable SSH/HTTP/HTTPS in the security groups
* SSH as ``ubuntu@[your ami]``, ``centos@``, or ``ec2-user@``. 

Proceed to the OS-specific instructions below.

For further information, see [full AWS installation instructions](https://github.com/graphistry/graphistry-cli/blob/master/docs/aws.md).


### Azure

* Launch an Ubuntu 16.04 LTS Virtual Machine with an ``NC*`` GPU compute SKU, e.g., NC6 (hdd)
* Enable SSH/HTTP/HTTPS
* Check to make sure GPU is attached 

```
$ lspci -vnn | grep VGA -A 12
0000:00:08.0 VGA compatible controller [0300]: Microsoft Corporation Hyper-V virtual VGA [1414:5353] (prog-if 00 [VGA controller])
	Flags: bus master, fast devsel, latency 0, IRQ 11
	Memory at f8000000 (32-bit, non-prefetchable) [size=64M]
	[virtual] Expansion ROM at 000c0000 [disabled] [size=128K]
	Kernel driver in use: hyperv_fb
	Kernel modules: hyperv_fb

5dc5:00:00.0 3D controller [0302]: NVIDIA Corporation GK210GL [Tesla K80] [10de:102d] (rev a1)
	Subsystem: NVIDIA Corporation GK210GL [Tesla K80] [10de:106c]
	Flags: bus master, fast devsel, latency 0, IRQ 24, NUMA node 0
	Memory at 21000000 (32-bit, non-prefetchable) [size=16M]
	Memory at 1000000000 (64-bit, prefetchable) [size=16G]
	Memory at 1400000000 (64-bit, prefetchable) [size=32M]
```

Proceed to the OS-specific instructions below.

For further information, see [full Azure installation instructions](https://github.com/graphistry/graphistry-cli/blob/master/docs/azure.md).

### On-Premises


See [Recommended Deployment Configurations: Client, Server Software, Server Hardware](https://github.com/graphistry/graphistry-cli/blob/master/docs/hardware-software.md).

### Airgapped

Graphistry runs airgapped without any additional configuration. Pleae contact your systems representative for assistance with nvidia-docker-2 environment setup.


## 3. Linux Dependency Installation


If your environment already has `nvidia-docker-2`, `docker`, `docker-compose`, and `CUDA 9.2`, skip this section.


### Ubuntu 16.04 LTS
```
    $ git clone https://github.com/graphistry/graphistry-cli.git
    $ bash graphistry-cli/bootstrap.sh ubuntu-cuda9.2
```

### RHEL 7.4 / CentOS 7
*Note: Temporarily not supported on AWS/Azure*

```
    $ sudo yum install -y git
    $ git clone https://github.com/graphistry/graphistry-cli.git 
    $ bash graphistry-cli/bootstrap.sh rhel
```

### After

Log off and back in (full restart not required):  "`$ exit`", "`$ exit`"

**_Warning: Skipping this step means `docker` service may not be available_**

**_Warning: Skipping this step means Graphistry environment tests will not automatically run_**


### Test environment


These tests run upon exiting the bootstrap. You can invoke them manually at any time:

```
    $ run-parts --regex "test*" graphistry-cli/graphistry/bootstrap/ubuntu-cuda9.2
```

Ensure tests pass for `test-10` through `test-40`.

## 4. Graphistry Container Installation

Load the Graphistry containers into your system's registry:
```
docker load -i containers.tar
```


## 5. Start

Launch with `docker-compose up`, and stop with `ctrl-c`. To start as a background daemon, use `docker-compose up -d`.

Congratulations, you have installed Graphistry!

For a demo, try going to `http://MY_SITE/graph/graph.html?dataset=Twitter`, and compare to [the public version](https://labs.graphistry.com/graph/graph.html?dataset=Twitter).



# Configuration

**Strongly Recommended**:

After testing a base install works, configure the following:

* Setup `pivot` password
* Setup data persistence folders in case of restarts
* Generate API Key for developers & notebook users


See [configure.md](https://github.com/graphistry/graphistry-cli/blob/master/docs/configure.md) for connectors (Splunk, ElasticSearch, ...), passwords, ontology (colors, icons, sizes), TLS/SSL/HTTPS, backups to disk, and more.


# Maintenance

### AWS Marketplace

See [AWS Marketplace Administration](https://github.com/graphistry/graphistry-cli/blob/master/docs/aws_marketplace.md)

### OS Restarts

Graphistry automatically restarts in case of errors. In case of manual restart or reboot:

* On reboot, you may need to first run:
  * `sudo systemctl start docker`
* If using daemons:
  * `docker-compose restart`
  * `docker-compose stop` and `docker-compose start`
* Otherwise `docker-compose up`


### Upgrading

1. Backup any configuration and data: `.env`, `docker-compose.yml`, `data/*`, `etc/ssl`
2. Stop the Graphistry server if it is running: `docker-compose stop`
3. Load the new containers (e.g., `docker load -i containers.tar`) 
4. Edit and reload any config (`docker-compose.yml`, `.env`, `data/*`, `etc/ssl`)
5. Restart Graphistry: `docker-compose up` (or `docker-compose up -d`)



# Testing

**Environment**

If you downloaded the CLI:
```
run-parts --regex "test*" graphistry-cli/graphistry/bootstrap/ubuntu-cuda9.2
```

Note that these are _not_ deep tests of the environment.

**Healthchecks**

* Installation repositories are accessible:
  * ping www.github.com
  * ping shipyard.graphistry.com
  * ping us.gcr.io
* Nvidia infrastructure setup correctly
  * `nvidia-smi` reports available GPUs
  * `nvidia-docker run nvidia/cuda nvidia-smi` reports available GPUs
  * `nvidia-docker run graphistry/cljs:1.1 npm test` reports success (see airgapped alternative as well)
  * Using the image listed in `docker images`, running `nvidia-docker run us.gcr.io/psychic-expanse-187412/graphistry/release/viz-app:1024 nvidia-smi` reports available GPUs
* Configurations were generated: 
  * ``.config/graphistry/config.json``
  * ``httpd-config.json``
  * ``pivot-config.json``
  * ``viz-app-config.json``
* Services are running: ``docker ps`` reveals no restart loops on:
  * ``monolith-network-nginx``
  * ``monolith-network-pivot``
  * ``monolith-network-viz``
  * ``monolith-network-mongo``
  * ``monolith-network-db-bu``
  * ``monolith-network-pg``
* Services pass initial healthchecks:
  * ``site.com/central/healthcheck``
  * ``site.com/pivot/healthcheck``
  * ``site.com/worker/10000/healthcheck``
* Pages load
  * ``site.com`` shows Graphistry homepage
  * ``site.com/graph/graph.html?dataset=Facebook`` clusters and renders a graph
  * ``site.com/pivot`` loads a list of investigations
  * ``site.com/pivot/connectors`` loads a list of connectors
  * ^^^ When clicking the ``Status`` button for each connector, it reports green
  *  Opening and running an investigation in ``site.com/pivot`` uploads and shows a graph
* Data uploads
  * Can generate an API key with the CLI: ``graphistry`` --> ``keygen``
  * Can use the key to upload a visualization: https://graphistry.github.io/docs/legacy/api/0.9.2/api.html#curlexample
  * Can then open that visualization in a browser

**Notebooks**

Create the below notebook, fill in appropriate values for `GRAPHISTRY`. The expected result is a link, that when you click it, shows a graph with 3 nodes.

```
GRAPHISTRY = {
    'server': 'my.server.com', #no http, just domain
    'protocol': 'http',
    'key':  'MY_API_KEY'
}

!pip install pandas
import pandas as pd
edges_df=pd.DataFrame({'src': [0,1,2], 'dest': [1,2,0]})

!pip install graphistry
import graphistry
graphistry.register(**GRAPHISTRY)

graphistry.bind(source='src', destination='dest').edges(edges_df).plot(render=False)
```

For further information about the Notebook client, see the OSS project [PyGraphistry](http://github.com/graphistry/pygraphistry) ( [PyPI](https://pypi.org/project/graphistry/) ).

# Troubleshooting


See [further documentation](https://github.com/graphistry/graphistry-cli/blob/master/docs).
