# Managing a Graphistry Deployment

Welcome to Graphistry! 

## Quick start

The fastest way to install, admininster, and use Graphistry is to [quick launch Graphistry from the AWS Marketplace](https://www.graphistry.com/get-started) (see [walkthrough tutorial & videos](https://www.graphistry.com/blog/marketplace-tutorial)). AWS Marketplace launches a Graphistry instance in your private cloud and runs with zero additional configuration necessary.

## Advanced administration

Graphistry supports advanced command-line administration via standard docker-compose `.yml` / `.env` files and `nginx` / `caddy` configuration.

The `graphistry-cli` repository contains 
* Documentation for operating the Graphistry Docker container (install, configure, start/stop, & debug)
* Documentation for configuring the software: `nginx`, connectors, and ontology

## Manual Install for Nvidia Environments, Including AWS

NOTE: Managed Graphistry instances do not require any of these steps.

**Get Graphistry container**

Download the latest distribution from the [release list](https://graphistry.zendesk.com/hc/en-us/articles/360033184174-Enterprise-Releases) on the support site. 

If you were not already given an enterprise administrator account for the support site, please contact your Graphistry support staff.

**Install Graphistry container**

If `nvidia` is already your `docker info | grep Default` runtime:

```
############ Install & Launch
wget -O release.tar.gz "https://..."
tar -xvvf release.tar.gz
docker load -i containers.tar
docker-compose up -d
```

**Docker: Launch & Configure Nvidia for Docker**

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

The Graphistry environnment depends soley on [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`, and ships with all other dependencies built in.


## Top Commands

|  	|  	|  	|
|--: |---	|---	|
| **Install** 	| `docker load -i containers.tar` 	| Install the `containers.tar` Graphistry release from the current folder. You may need to first run `tar -xvvf my-graphistry-release.tar.gz`.	|
| **Start (interactive)** 	| `docker-compose up` 	| Starts Graphistry, close with ctrl-c 	|
| **Start (daemon)** 	| `docker-compose up -d` 	| Starts Graphistry as background process 	|
| **Start (namespaced)** 	| `docker-compose -p my_namespace up` 	| Starts Graphistry with a unique name (in case of multiple versions). NOTE: must modify volume names in `docker-compose.yml`. 	|
| **Stop** 	| `docker-compose stop` 	| Stops Graphistry 	|
| **Restart** 	| `docker restart <CONTAINER>` 	|  	|
|  **Status** 	| `docker-compose ps`, `docker ps`, and `docker status` 	|  Status: Uptime, healthchecks, ...	|
|  **API Key** 	| docker-compose exec streamgl-vgraph-etl curl "http://0.0.0.0:8080/api/internal/provision?text=MYUSERNAME" 	|  Generates API key for a developer or notebook user	|
| **Logs** 	|  `docker logs <CONTAINER>` (or `docker exec -it <CONTAINER>` followed by `cd /var/log`) 	|  Ex: Watch all logs, starting with the 20 most recent lines:  `docker-compose logs -f -t --tail=20`	|
| **Reset**     | `docker-compose down -v && docker-compose up` | Stop Graphistry, remove all internal state (including user accounts), and start fresh .  |
| **Create users** | Use Admin Panel (see [Create Users](docs/user-creation.md)) |

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
* On-prem: 
    * Graphistry-provided tarball
    * Linux with [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`
    * RAPIDS-compatible NVidia GPU: Pascal or later. Recommended G3+ on AWS and NCv2+ Series on Azure.
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

* Launch an Ubuntu 16.04+ LTS Virtual Machine with an ``NCv2+`` or ``ND+`` GPU compute SKU (Pascal+)
* Enable SSH/HTTP/HTTPS
* Ensure a GPU is attached:

```
$ nvidia-smi
$ lspci -vnn | grep VGA -A 12
```

Proceed to the OS-specific instructions below.

For further information, see [full Azure installation instructions](https://github.com/graphistry/graphistry-cli/blob/master/docs/azure.md).

### On-Prem


See [Recommended Deployment Configurations: Client, Server Software, Server Hardware](https://github.com/graphistry/graphistry-cli/blob/master/docs/hardware-software.md).

### Airgapped

Graphistry runs airgapped without any additional configuration. Pleae contact your systems representative for assistance with nvidia-docker-2 environment setup.


## 3. Linux Dependency Installation

The Graphistry environnment depends soley on [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`, and ships with all other dependencies built in. See instructions in this document for making Nvidia the default Docker runtime via `daemon.json`.

We do not recommend manually installing dependencies. If you must manually install dependencies, see our [RHEL 7.6 sample](docs/rhel_7_6_setup.md), and contact our team.



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


### Upgrade, backup, and migrate

See [instructions to update, backup, and migrate](https://github.com/graphistry/graphistry-cli/blob/master/docs/update-backup-migrate.md)

# Testing

* `docker ps` reports no "unhealthy", "restarting", or prolonged "starting" services
* Nvidia infrastructure setup correctly
  * `nvidia-smi` reports available GPUs  <-- tests host drivers
  * `docker run --runtime=nvidia nvidia/cuda nvidia-smi` reports available GPUs <-- tests Docker installation
  * `docker run --rm nvidia/cuda  nvidia-smi` reports available GPUs <-- tests Docker defaults
  * `docker run graphistry/cljs:1.1 npm test` reports success (see airgapped  <-- tests driver versioning)
  * "docker run --rm grph/streamgl-gpu:`cat VERSION`-dev nvidia-smi" reports available GPUs
* Pages load when logged in
  * ``site.com`` shows Graphistry homepage
  * ``site.com/graph/graph.html?dataset=Facebook`` clusters and renders a graph
  * ``site.com/pivot`` loads a list of investigations
  * ``site.com/pivot/connectors`` loads a list of connectors
  * ^^^ When clicking the ``Status`` button for each connector, it reports green
  *  Opening and running an investigation in ``site.com/pivot`` uploads and shows a graph
* Notebooks
  * Running the analyst notebook example generates running visualizations (see logged-in homepage)
  * For further information about the Notebook client, see the OSS project [PyGraphistry](http://github.com/graphistry/pygraphistry) ( [PyPI](https://pypi.org/project/graphistry/) ).

# Troubleshooting

See [further documentation](https://github.com/graphistry/graphistry-cli/blob/master/docs).
