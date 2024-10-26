# Manual Graphistry Installation

We highly recommend getting started with quick launching a preconfigured [AWS Marketplace](aws_marketplace.md) or [Azure Marketplace](azure_marketplace.md) instance. When that is not an option, you may still be able to use a preconfigured GPU environment or automation script from Graphistry. 

If none of those situations apply, read on for how to go to an unconfigured Linux instance to running Graphistry.


## Contents

1. Prerequisites
2. Instance Provisioning
 * AWS Marketplace & Azure Marketplace
 * AWS & Azure BYOL
 * On-Prem
 * Airgapped
3. Linux Dependency Installation
4. Graphistry Container Installation
5. Start!



## 1. Prerequisites

* Graphistry-provided tarball
* Linux with [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`
* RAPIDS-compatible NVidia GPU: Pascal or later.

For further information, see [Recommended Deployment Configurations: Client, Server Software, Server Hardware](hardware-software.md).

## 2. Instance Provisioning

### AWS & Azure Marketplace

Skip almost all of these steps by instead running through [AWS Marketplace](aws_marketplace.md) and [Azure Marketplace](azure_marketplace.md).

### AWS, Azure, & GCP BYOL

* **Start from an Nvidia instace**
<br>You can skip most of the steps by starting with an Nvidia NGC or Tensorflow instance. 
  * These still typically require installing `docker-compose` (and testing it), setting `/etc/docker/daemon.json` to default to the `nvidia-docker` runtime, and restarting `docker` (and testing it). See end of [RHEL 7.6](rhel_7_6_setup.md) and [Ubuntu 18.04 LTS](ubuntu_18_04_lts_setup.md) sample scripts for install and test instruction.
* **Start from raw Ubuntu/RHEL**
<br>You can build from scratch by picking a fully unconfigured starting point and following the [RHEL 7.6](rhel_7_6_setup.md) and [Ubuntu 18.04 LTS](ubuntu_18_04_lts_setup.md) On-Prem Sample instructions. Contact Graphistry staff for automation script assistance if also applicable.

### On-Prem

See [Recommended Deployment Configurations: Client, Server Software, Server Hardware](hardware-software.md).

### Airgapped

Graphistry runs airgapped without any additional configuration. 


## 3. Linux Dependency Installation

The Graphistry environnment depends soley on [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`, and ships with all other dependencies built in. 

See our sample scripts for [RHEL 7.6](rhel_7_6_setup.md) and [Ubuntu 18.04 LTS](ubuntu_18_04_lts_setup.md). For automating this process, please contact Graphistry staff.



## 4. Graphistry Container Installation

Load the Graphistry containers into your system's registry:
```
docker load -i containers.tar
```


## 5. Start

Launch with `docker-compose up`, and stop with `ctrl-c`. To start as a background daemon, use `docker-compose up -d`.

Congratulations, you have installed Graphistry!
