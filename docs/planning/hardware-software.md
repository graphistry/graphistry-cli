# Recommended Deployment Configurations: Client, Server Software, Server Hardware


This document focused on technical requirements. See the [deployment planning article](deployment-planning.md) for broader considerations such as capacity planning.

The recommended server configuration is [AWS Marketplace](../install/cloud/aws_marketplace.md) and [Azure Marketplace](../install/cloud/azure_marketplace.md) with instance types noted on those screens. The one-click launcher deploys a fully preconfigured instance.

Graphistry Enterprise also ships as a Docker container that runs in Linux Nvidia GPU environments that are compatible with [NVIDIA RAPIDS](https://rapids.ai/) and the [Nvidia Docker runtime](https://github.com/NVIDIA/nvidia-docker). It is often   run in the cloud as well.

## Contents

* Overview
* Client
* Server Software: Cloud, Kubernetes, OS, Docker, Avoiding Root Users
* Server Hardware: Capacity Planning

## Overview

* **Client**: Chrome/Firefox from the last 3 years, WebGL enabled (1.0+), and 100KB/s download ability
* **Server**: 
- Minimal: x86 Linux server with 4+ CPU cores, 16+ GB CPU RAM (3GB per concurrent user), 150GB+ disk, and 1+ Nvidia GPUs (Pascal onwards for [NVIDIA RAPIDS](https://rapids.ai/)) with 4+ GB RAM each (1+ GB per concurrent user), 64 GB disk
- Recommended: Ubuntu 24.04 LTS (22.04 and 20.04 LTS also supported), 8+ CPU cores, 64GB+ CPU RAM, 150GB+ disk, Nvidia Pascal or later (Tesla, Turing, Volta, RTX, ...) with 12+GB GPU RAM and 100GB+ disk
- CUDA driver rated for [NVIDIA RAPIDS](https://rapids.ai/) 
- [Nvidia Docker runtime](https://github.com/NVIDIA/nvidia-docker) set as default runtime for Docker. Use `./graphistry` wrapper (wraps docker compose with GPU, telemetry, and cluster configuration).
 

## Client

A user's environment should support Graphistry if it supports Youtube, and even better, Netflix.

The Graphistry client runs in standard browser configurations:

* **Browser**: Chrome and Firefox from the last 3 years, and users regularly report success with other browsers

* **WebGL**: WebGL 1.0 is required. It is 8+ years old and browsers support non-GPU software rendering, so most client devices, including phones and tablets, support it: check browser settings for enabling. Graphistry runs fine on both integrated and discrete graphic cards, with bigger graphs working better on bigger GPUs.

* **Network**: 100KB+/s download speeds, and we recommend 1MB+/s if often using graphs with 100K+ nodes and edges. 

* **Operating System**: All

***Recommended***: Chrome from last 2 years on a device from the last 4 years and a 1MB+/s network connection


## Server Software: Hosted, Cloud, Virtualization, OS, Docker, Avoiding Root Users

Graphistry is modern container software and thus can be flexibly deployed. You can run via graphistry.com, on-prem, prebuilt via your cloud provider's marketplace, and self-automated in your cloud (Amazon EC2, Google GCP, and Microsoft Azure). 

### Hosted (Alpha)

You can access Graphistry as an account at Graphistry Cloud (graphistry.com):

* Isolated tier: Avoid administration costs but still guarantee dedicated & isolated resources by running managed by Graphistry
* Shared tier: Save money by running on shared resources
* In alpha - contact for further information

### Cloud

For all of the below, ensure ports 22, 80, 443, and 100GB+ disk

*Supported AWS Instances*:

* g4dn.xlarge (T4) ***Recommended for testing and single user***
* g4dn.2xlarge+ / P3.2+ (V100) / P4+ (A100) ***Recommended for team use***

AWS support includes Marketplace, prebuilt AMIs / BYOL, and from-source automation
Pricing: https://ec2instances.info ($1.4K+/mo at time of writing)

*Supported Azure instances*:

* NC6s_v2+ (P100) ***Recommended for testing and initial workloads***
* NC6s_v3+ (V100)
* ND (P40) **Not recommended**
* NDv2 (V100)
* Experimental: T4 and A100

Azure support includes Marketplace, prebuilt VHDs / BYOL, and from-source automation
Pricing: https://azure.microsoft.com/en-us/pricing/calculator/  ($960+/mo at time of writing)

*Tested GCP Instances*:

Use instance type `n1` and attach one of the following GPUs:

* P100 ***Recommended for team use***
* V100
* T4 ***Recommended for testing and single user***
* Experimental: A100

GCP support includes BYOL; contact for automation reference scripts & roadmap details
Pricing: https://cloud.google.com/compute/gpus-pricing ($440+/mo at time of writing)

See the hardware provisioning section to pick the right configuration for you.

Please contact for discussion of multi-GPU scenarios.

### Kubernetes - Experimental

See [graphistry/graphistry-helm repository](https://github.com/graphistry/graphistry-helm)

* Same software/hardware requirements as elsewhere in this document
* Runs as pods on one node and support for multi-node coming
* Tested support for self-hosted (ex: minikube), Azure AKS, and Amazon EKS

### Virtualization

Graphistry [works with VMWare, Nutanix, and likely other NGC/RAPIDS-capable virtualization environments](../install/on-prem/vGPU.md). Please contact our team for further information. The surrounding HW/SW requirements still apply.

* You will need to install the same-version Nvidia driver in both the hypervisor and guest OS, and depending on virtualization approach, managed Nvidia vGPU licensing

* Nvidia vGPU virtualization does not currently support CUDA Unified Memory, so configure Graphistry setting `RMM_ALLOCATOR=default` in `data/config/custom.env`

* You may additionally consider also using separate VDI servers for accelerating the frontend (WebGL) experience as well, if you have excess GPU capacity on hardware better than available on client devices 

Running Graphistry in hypervisors is less common, so we recommend contacting staff for this path.

### OS & Docker

Graphistry runs preconfigured with a point-and-click launch on Amazon Marketplace and Azure Marketplace and prebuilt images for the same. 

Graphistry regularly runs on:

* Ubuntu 24.04 LTS ***Recommended*** (22.04 and 20.04 LTS also supported)
* Red Hat (RHEL) 8.x, 9.x: See `etc/scripts/bootstrap` for setup scripts

Both support Nvidia / Docker:

* CUDA driver rated for [NVIDIA RAPIDS](https://rapids.ai/) (CUDA 11.0 for RAPIDS 2022.x, and 11.5+ for Graphistry AI extensions)
* [Nvidia Docker *native* runtime](https://github.com/NVIDIA/nvidia-docker)  (for after Docker 19.03)
* Docker with nvidia runtime as default (check: `docker info | grep -i runtime` => default `nvidia`)
  * Use `./graphistry` wrapper instead of raw `docker compose` - it wraps docker compose with GPU, telemetry, and cluster configuration

Common Docker tweaks:

* [sudo-less Docker](https://docs.docker.com/engine/install/linux-postinstall/): Create a Docker group and make a service account in that group
* [Set a TMPDIR](https://stackoverflow.com/questions/38747082/docker-container-has-no-tmpdir-environmental-variable)
* Save Docker images to a larger mount by [setting the data-root](https://docs.docker.com/config/daemon/systemd/#custom-docker-daemon-options)

See your Graphistry distribution's folder `etc/scripts/bootstrap` for Ubuntu, Red Hat, and air-gapped reference installers. Marketplace deployments come preconfigured with the latest working drivers and security patches.


### User: Root vs. Not, Permissions

Installing Docker and Nvidia dependencies currently require root user permissions.

Graphistry can be installed and run as an unprivileged user as long as it has access to Docker and the Nvidia runtime. 

### Storage

* Recommended: Network-attached storage for persisting visualizations and investigations.

* Recommended: 100GB+ (10-20GB for airgapped docker images + 3x for swap)

## Server Hardware:  Capacity Planning

Graphistry utilization increases with the number of concurrent visualizations and the sizes of their datasets. 
Most teams will only have a few concurrent users and a few concurrent sessions per user. So, one primary server, and one spillover or dev server, gets a team far.

For teams doing single-purpose multi-year purchases, we generally recommend more GPUs and more memory: As Graphistry adds further scaling features, users will be able to upload more data and burst to more devices.

Developer systems should match the minimum requirements, though GPU memory can go down to 2GB (recommended: 4GB+).

Benchmarking is a useful means to capture metrics of various workloads to understand their hardware requirements and accurately size systems, for more see [Benchmarking Graphistry for Capacity Planning](https://github.com/graphistry/graphistry-cli/blob/master/docs/benchmarking.md)

### Network

A Graphistry server must support 1MB+/s per expected concurrent user. A moderately used team server may stream a few hundred GB / month.

* The server should allow http/https access by users and ssh by the administrator.
* TLS certificates can be installed (Caddyfile)
* The Graphistry server may invoke various database connectors: Those systems should enable firewall and credential access that authorizes authenticated remote invocations from the Graphistry server.

#### Air-gapped installation

Graphistry simplifies air-gapped installation. It ships as self-contained Docker image tarballs. 

You will still need to install Nvidia drivers and Docker into the host environment. For Red Hat 8.x, contact staff for reference scripts for generating offline installers for these dependencies.

#### Air-gapped operation

Graphistry runs out-of-the-box without network access


### GPUs, GPU RAM, GPU drivers

Graphistry requires [NVIDIA RAPIDS](https://rapids.ai/)-compatible  GPUs. If you can make a RAPIDS Docker container work, Graphistry should also work.

The following GPUs, Pascal and later (Pascal, Tesla, Turing, Volta, RTX) are known to work with Graphistry:

* T4, P100, V100, RTX, A100, H100
* ... Found in DGX, DGX2, and AWS/Azure/GCP

The GPU should provide 1+ GB of memory per concurrent user. A minimum of 4GB of GPU RAM is required, and 12GB+ is recommended. Lower is possible for development. For help evaluating GPUs, we recommend reaching out to the Graphistry team or the [RAPIDS.ai community](https://rapids.ai/community.html).

RAPIDS requires specific Nvidia drivers. Graphistry releases align with [Nvidia RAPIDS.ai](https://rapids.ai/) releases, so pick drivers compatible with the RAPIDS.ai distribution from the same time period.

### CUDA Compatibility Matrix

| Graphistry Version | RAPIDS Version | CUDA Version | Min Driver | Recommended Driver |
|-------------------|----------------|--------------|------------|-------------------|
| 2.45.x+ | 24.10+ | 11.8 or 12.8 | 520.x | 535.x+ |
| 2.42.x - 2.44.x | 24.06 | 11.8 or 12.4 | 520.x | 535.x+ |
| 2.40.x - 2.41.x | 23.10 | 11.8 | 520.x | 525.x+ |
| 2.38.x - 2.39.x | 23.06 | 11.8 | 515.x | 525.x+ |

**Notes**:
- Graphistry ships dual CUDA builds (11.8 + 12.x) for driver flexibility
- CUDA 12.8 provides native Blackwell support and better performance on Hopper/Ada GPUs
- CUDA 11.8 provides broader driver compatibility for older systems
- Check driver compatibility: `nvidia-smi` shows max supported CUDA version

### GPU Architecture Support

| Architecture | Compute Capability | GPUs | Min CUDA | Status |
|-------------|-------------------|------|----------|--------|
| Blackwell | 10.0, 10.3 | B100, B200, GB200, B300 | 12.8 (native) | Full support |
| Hopper | 9.0 | H100, H200, GH200 | 11.8+ | Full support |
| Ada Lovelace | 8.9 | L40S, RTX 4090 | 11.8+ | Full support |
| Ampere | 8.0, 8.6 | A100, A10, A30, RTX 3090 | 11.0+ | Full support |
| Turing | 7.5 | T4, RTX 2080 | 10.2+ | Full support |
| Volta | 7.0 | V100 | 10.0+ | Full support |
| Pascal | 6.0, 6.1 | P100, P40, GTX 1080 | 9.2+ | Full support |

**Blackwell Note**: CUDA 12.8+ generates native Blackwell cubins. Older CUDA versions can run on Blackwell via PTX JIT compilation but without architecture-specific optimizations.

If also using a hypervisor, the hypervisor GPU driver should match the guest OS GPU driver, and due to vGPUs not currently supporting CUDA Unified Memory, set `RMM_ALLOCATOR=default` in Graphistry setting file `data/config/custom.env`.

### GPU Memory Protection

For production deployments, enable the **GPU Memory Watcher** to automatically monitor GPU memory usage and terminate runaway processes before they cause OOM (Out of Memory) errors:

```bash
# In data/config/custom.env
FEP_GPU_WATCHER_ENABLED=1
FEP_GPU_WATCHER_WARN_THRESHOLD=70%
FEP_GPU_WATCHER_KILL_THRESHOLD=90%
FEP_GPU_WATCHER_EMERGENCY_THRESHOLD=95%
```

See [Performance Tuning - GPU Memory Watcher](../debugging/performance-tuning.md#gpu-memory-watcher) for detailed configuration.

### GPU Configuration Tools

Use the [GPU Configuration Wizard](../tools/gpu-config-wizard.md) to auto-generate optimal GPU settings for your hardware:

```bash
./etc/scripts/gpu-config-wizard.sh -E ./data/config/custom.env
```

The wizard supports 140+ hardware presets for AWS, Azure, GCP, NVIDIA DGX, and more. See [GPU Configuration Wizard](../tools/gpu-config-wizard.md) for the full preset list and usage details.

### CPU Cores & CPU RAM

CPU cores & CPU RAM should be provisioned in proportion to the number of GPUs and users:

* CPU Cores: 
  * Minimum: 4
  * Recommended: 8+, with 4-8 x86 CPU cores per GPU
* CPU RAM: 
  * Minimum: 16GB
  * Recommended: 16GB single user and +2 GB per concurrent user


### Multi-GPU, Multi-Node, and Multi-Tenancy

Graphistry virtualizes a single GPU for shared use by multiple users and can vertically scale to multiple CPUs+GPUs on the same node for additional users. 

* Multitenancy via multiple GPUs: You can use more GPUs to handle more users and give more performance isolation between users. We recommend separating a few heavy users from many light users, and developers from non-developers.

* Acceleration via multiple GPUs: Graphistry is investigating how to achieve higher speeds via multi-GPU acceleration, but the current benefits are only for multitenancy.

### HA

Graphistry resiliency typically comes in multiple forms:

* User separation: For larger deployments, we recommend separating developers (unpredictable), power users (many large graphs), and regular users (many small sessions).

* Physical resource isolation: Graphistry can run on the same device as other software as long as they respect Graphistry's  CPU, GPU, and network resources. You can use Docker to limit Graphistry execution to specific CPU, GPU, and network resources. Check your other software to ensure that it can likewise be configured to not interfere with sibling workloads. 

* Process isolation: You may run multiple Graphistry instances on the same node to increase resiliency between groups of users. This can be combined with same-node physical resource isolation. This increases resiliency up to hardware and driver failure. However, note that each Graphistry instance will consume 1.5GB+ of GPU RAM.

* Logical separation & replication: You may want to further tune software replication factors. Graphistry runs as multiple containerized shared services with distinct internal replication modes and automatic restarts. Depending on the service, a software failure may impact live sessions of cotenant users or prevent service for 3s-1min.  Within a node, you may choose to either tune internal service replication or run multiple Graphistry instances.

* Safe upgrades: Due to Graphistry's use of version-tagged Docker images and project-namespaceable orchestrations (via `./graphistry` wrapper for docker compose), upgrades can be performed through:
  * New instances (e.g., DNS switch): recommended, especially for cloud
  * Installation of a concurrent version
Contact support staff for migration information. 

### RAPIDS

Graphistry RAPIDS support can be used for more than investigation visualization and automation. See the deploy planning docs for [how to think about RAPIDS and GPUs as core compute infrastructure](deployment-planning.md#4-planning-for-multi-year-and-rapids-scaleout).
