# Manual Graphistry Installation

We highly recommend getting started with quick launching a preconfigured [AWS Marketplace](../cloud/aws_marketplace.md) or [Azure Marketplace](../cloud/azure_marketplace.md) instance. When that is not an option, you may still be able to use a preconfigured GPU environment or automation script from Graphistry. 

If none of those situations apply, read on for how to go to an unconfigured Linux instance to running Graphistry.


## Contents

0. Quick Install & Launch
1. Prerequisites
2. Instance Provisioning
 * AWS Marketplace & Azure Marketplace
 * AWS & Azure BYOL
 * On-Prem
 * Airgapped
3. Linux Dependency Installation
4. Graphistry Container Installation
5. Start!


## 0. Quick Install & Launch

If `nvidia` is already your `docker info | grep Default` runtime:

```bash
wget -O release.tar.gz "https://..."
tar -xvvf release.tar.gz
docker load -i containers.tar.gz
./graphistry up -d
```

## 1. Prerequisites

* Graphistry-provided tarball
* Linux with [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`
* RAPIDS-compatible NVidia GPU: Pascal or later.

For further information, see [Recommended Deployment Configurations: Client, Server Software, Server Hardware](../../planning/hardware-software.md).

### Manual Graphistry container download

Download the latest enterprise distribution from the [enterprise release list](https://graphistry.zendesk.com/hc/en-us/articles/360033184174-Enterprise-Releases) on the support site.  Please contact your Graphistry support staff for access if not available.


## 2. Instance Provisioning

### AWS & Azure Marketplace

Skip almost all of these steps by instead running through [AWS Marketplace](../cloud/aws_marketplace.md) and [Azure Marketplace](../cloud/azure_marketplace.md).

### AWS, Azure, & GCP BYOL

* **Start from an Nvidia instace**
<br>You can skip most of the steps by starting with an Nvidia NGC or Tensorflow instance. 
  * These still typically require setting `/etc/docker/daemon.json` to default to the `nvidia-docker` runtime, and restarting `docker` (and testing it). See `etc/scripts/bootstrap/` in your Graphistry distribution for current setup scripts.
* **Start from raw Ubuntu/RHEL**
<br>You can build from scratch by picking a fully unconfigured starting point. See `etc/scripts/bootstrap/` in your Graphistry distribution for Ubuntu and RHEL setup scripts. Contact Graphistry staff for automation script assistance if also applicable.

### On-Prem

See [Recommended Deployment Configurations: Client, Server Software, Server Hardware](../../planning/hardware-software.md).

### Airgapped

Graphistry runs airgapped without any additional configuration. 


## 3. Linux Dependency Installation

The Graphistry environnment depends soley on [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`, and ships with all other dependencies built in. 

See `etc/scripts/bootstrap/` in your Graphistry distribution for Ubuntu and RHEL setup scripts. For legacy OS references, see [Legacy Setup Guides](legacy/index.rst). For automating this process, please contact Graphistry staff.



## 4. Graphistry Container Installation

Load the Graphistry containers into your system's registry:
```
docker load -i containers.tar
```


## 5. Start

Launch with `./graphistry up`, and stop with `ctrl-c`. To start as a background daemon, use `./graphistry up -d`.

Congratulations, you have installed Graphistry!
