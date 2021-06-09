# Welcome to Graphistry: Admin Guide

Graphistry is the most scalable graph-based visual analysis and investigation automation platform. It supports both cloud and on-prem deployment options. Big graphs are tons of fun!

The documentation here covers system administration

See bottom of page for table of contents and additional resources.

#### Get

Pick an [appropriate hardware/software configuration](hardware-software.md):
* Graphistry Hub: Graphistry manages Hub for its users
* AWS/Azure Marketplace: See below instructions
* Docker (self-hosted): See [enterprise release portal](https://graphistry.zendesk.com/hc/en-us/articles/360033184174)

#### Support

Email, Zoom, Slack, phone, tickets -- we encourage using the [Graphistry support channel](https://www.graphistry.com/support) that works best for you. We want you and your users to succeed! 

---

## Quick launch: Managed

[AWS and Azure marketplaces](https://www.graphistry.com/get-started): The fastest way to start using Graphistry is to quick launch a preconfigured private Graphistry instance on [AWS and Azure marketplaces](https://www.graphistry.com/get-started)

It runs in your private cloud provider account and is configured to autostart. See [AWS launch walkthrough tutorial & videos](https://www.graphistry.com/blog/marketplace-tutorial) and linked guides for optional post-launch configuration and maintenance.

Out-of-the-box configurations include GPU drivers, Docker with Nvidia runtime, multi-GPU support, Graphistry installation, auto-start on instance stop/restart, and more

---

## Quick launch: Manual

Requirements: [Download Graphistry](https://graphistry.zendesk.com/hc/en-us/articles/360033184174) and [verify docker-compose is setup for Nvidia runtimes](docs/testing-an-install.md#6-quick-testing-and-test-gpu)

**1. Install** if not already available from the folder with `containers.tar.gz`, and likely using `sudo`:

```bash
docker load -i containers.tar.gz
```

Note: In previous versions (< `v2.35`), the file was `containers.tar`


**2. Launch** from the folder with `docker-compose.yml` if not already up, and likely using `sudo`:

```bash
docker-compose up -d
```

Note: Takes 1-3 min, and around 5 min, `docker ps` should report all services as `healthy`

**3. Test:**  Go to 

```
http://localhost
```

* Create an account, and then try running a prebuilt Jupyter Notebook from the dashboard!
  * The first account gets an admin role, upon which account self-registration closes. Admins can then invite users or open self-registration. See [User Creation](docs/user-creation.md) for more information.

* Try a visualization like http://localhost/graph/graph.html?dataset=Facebook&play=5000&splashAfter=false 
  * **Warning**: First viz load may be slow (1 min) as RAPIDS generates **just-in-time** code for each GPU worker upon first encounter, and/or require a page refresh

---


## Top commands

Graphistry supports advanced command-line administration via standard `docker-compose`, `.yml` / `.env` files, and `caddy` reverse-proxy configuration.

### Login to server

| Image | Command |
|--: |:-- |
| **AWS** | `ssh -i [your_key].pem ubuntu@[your_public_ip]` |
| **Azure** | `ssh -i [your_key].pem [your_user]@[your_public_ip]` <br> `ssh [your_user]@[your_public_ip]` (pwd-based) |
| **Google** | `gcloud compute [your_instance] ssh` |
| **On-prem / BYOL** | Contact your admin |

### CLI commands

All likely require `sudo`. Run from where your `docker-compose.yml` file is located:  `/home/ubuntu/graphistry` (AWS), `/var/graphistry` (Azure), or `/var/graphistry/<releases>/<version>` (recommended on-prem).

|  TASK	| COMMAND 	| NOTES 	|
|--: |:---	|:---	|
| **Install** 	| `docker load -i containers.tar.gz` 	| Install the `containers.tar.gz` Graphistry release from the current folder. You may need to first run `tar -xvvf my-graphistry-release.tar.gz`.	|
| **Start <br>interactive** 	| `docker-compose up` 	| Starts Graphistry, close with ctrl-c 	|
| **Start <br>daemon** 	| `docker-compose up -d` 	| Starts Graphistry as background process 	|
| **Start <br>namespaced (concurrent)** 	| `docker-compose -p my_unique_namespace up` 	| Starts Graphistry in a specific namespace. Enables running multiple independent instances of Graphistry. NOTE: Must modify Caddy service in `docker-compose.yml` to use non-conflicting public ports, and likewise change global volumes to be independent. 	|
| **Stop** 	| `docker-compose stop` 	| Stops Graphistry 	|
| **Restart (soft)** 	| `docker restart <CONTAINER>` 	| Soft restart. May also need to restart service `nginx`. 	|
| **Restart (hard)** 	| `docker up -d --force-recreate --no-deps <CONTAINER>` 	|  Restart with fresh state. May also need to restart service `nginx`.	|
| **Reset**     | `docker-compose down -v && docker-compose up -d` | Stop Graphistry, remove all internal state (including the user account database!), and start fresh .  |
| **Status** 	 | `docker-compose ps`, `docker ps`, and `docker status` 	|  Status: Uptime, healthchecks, ...	|
| **GPU Status** | `nvidia-smi` | See GPU processes, compute/memory consumption, and driver.  Ex: `watch -n 1.5 nvidia-smi`. Also, `docker run --rm -it nvidia/cuda:latest nvidia-smi` for in-container test. |
| **1.0 API Key** | docker-compose exec streamgl-vgraph-etl curl "http://0.0.0.0:8080/api/internal/provision?text=MYUSERNAME" 	|  Generates API key for a developer or notebook user	(1.0 API is deprecated)|
| **Logs** 	|  `docker-compose logs <CONTAINER>` 	|  Ex: Watch all logs, starting with the 20 most recent lines:  `docker-compose logs -f -t --tail=20 forge-etl-python`	. You likely need to switch Docker to use the local json logging driver by  deleting the two default managed Splunk log driver options in `/etc/docker/daemon.json` and then restarting the `docker` daemon (see below). |
| **Create Users** | Use Admin Panel (see [Create Users](docs/user-creation.md)) or `etc/scripts/rest` |
| **Restart Docker Daemon** | `sudo service docker restart` | Use when changing `/etc/docker/daemon.json`, ... |
| **Jupyter shell**| `docker exec -it -u root graphistry_notebook_1 bash` then `source activate rapids` | Use for admin tasks like global package installs |


## Manual enterprise install

NOTE: Managed Graphistry instances do not require any of these steps.

The Graphistry environnment depends soley on [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`, and ships with all other dependencies built in.

### Test your environment setup


You can test your GPU environment via Graphistry's [base RAPIDS Docker image on DockerHub](https://hub.docker.com/r/graphistry/graphistry-blazing):

```
docker run --rm -it --entrypoint=/bin/bash graphistry/graphistry-blazing:latest -c "source activate rapids && python3 -c \"import cudf; print(cudf.DataFrame({'x': [0,1,2]})['x'].sum())\""
```

=>
```
3
```

See [GPU testing](docs/testing-an-install.md#6-quick-testing-and-test-gpu) to identify individual issues.

### Manual environment setup

See sample [Ubuntu 18.04 TLS](./docs/ubuntu_18_04_lts_setup.md) and [RHEL 7.6](./docs/rhel_7_6_setup.md) environment setup scripts for Nvidia drivers, Docker, nvidia-docker runtime, and docker-compose. See [Testing an Install](docs/testing-an-install.md) for environment testing.

Please contact Graphistry staff for environment automation options. 

### Manual Graphistry container download

Download the latest enterprise distribution from the [enterprise release list](https://graphistry.zendesk.com/hc/en-us/articles/360033184174-Enterprise-Releases) on the support site.  Please contact your Graphistry support staff for access if not available.

### Manual Graphistry container installation

If `nvidia` is already your `docker info | grep Default` runtime:

```bash
############ Install & Launch
wget -O release.tar.gz "https://..."
tar -xvvf release.tar.gz
docker load -i containers.tar.gz
docker-compose up -d
```


## FAQ

* Where are the docs? See this [GitHub repository](https://github.com/graphistry/graphistry-cli) for admin docs and [Graphistry Hub docs](http://hub.graphistry.com/docs) (or http://your_graphistry/docs) for analyst and developer docs

* Where do I get help? Whether community chat, email, tickets, a call, or even a training, [pick the most convienent option](https://www.graphistry.com/support)

* Can Graphistry run in the cloud? Yes - privately both via a [preconfigured AWS/Azure marketplace](https://www.graphistry.com/get-started) and as a self-managed docker binary. Contact our team for upcoming managed Graphistry Hub cloud tiers.

* Can Graphistry run privately? 
  * On-prem, including air-gapped, as a team backend server or a Linux-based analyst workstation, via docker image
  * Cloud, via prebuilt marketplace instance
  * Cloud, via docker image
  
* Can Graphistry run in ...
  * A VM: [Yes, including VMWare vSphere, Nutanix AHV, and anywhere else Nvidia RAPIDS.ai runs](docs/vGPU.md). Just set `RMM_ALLOCATOR=default` in your `data/config/custom.env` to avoid relying on CUDA Unified Memory, which vGPUs do not support.
  * Ubuntu / Red Hat / ... : Yes, just ensure the Nvidia Docker runtime is set as the default for docker-compose. We can assist with reference environment bootstrap scripts.
  
* How do I do license management? 
  * Graphistry does not require software-managed license registration, we can work with your procurement team on self-reported use

* Do I need a GPU on the client? No, clients do not need a GPU. They do need WebGL enabled, such as Chrome's non-GPU software emulation mode. If some of your users are on extremely limited environments, e.g., worse than a modern phone, or you have extremely powerful GPUs you would like to share, users report great experiences with GPU VDI technologies.

* Do I need a GPU on the server? Yes, the server requires an Nvidia GPU that is Pascal or later (T4, P100, V100, A100, RTX, ...). 

* Can Graphistry use multiple GPUs and multiple servers? 
  * Graphistry visualizations take advantage of multiple GPUs & CPUs on the same server to handle more users
  * Graphistry-managed Jupyter notebooks enable users to run custom GPU code, where each user may run multi-GPU tasks (e.g., via dask-cudf and BlazingSQL)
  * For high availability configuration and operation, contact staff for additional guidance
  * For many-node deployment and multi-GPU visualization acceleration, contact staff for roadmap

* Can I run multiple instances of Graphistry? Yes, see the command section for running in an isolated namespace. This is primarily for testing and in-place upgrading. If your goal is for Graphistry to use multiple CPUs and GPUs, it already does so automatically, so you can launch as usual.

* Can I use Graphistry from OS X / Windows? Yes, analysts can use any modern browser on any modern OS such as Chrome on Windows and Firefox on OS X, and even on small devices like Android phones and Apple tablets. The server requires Linux (Ubuntu, RHEL, ...) with a GPU. A self-contained analyst workstation would be Linux based.

* How do I try it out?
  * Notebook/API users can get a free account on [Graphistry Hub](https://www.graphistry.com/get-started)
  * Interact with pregenerated live visualizations on the [PyGraphistry gallery](https://github.com/graphistry/pygraphistry)
  * If you have a private sample CSV/XLS/etc., you can [spin up a private server in your AWS/Azure account](https://www.graphistry.com/get-started) and turn it off when done, and [our team is happy to help](https://www.graphistry.com/support)

* How can I test if my GPU supports Graphistry and my GPU environment is setup properly? Graphistry only requires a [RAPIDS-compatible](https://www.rapids.ai) Docker environment, so you can use the community resources for that. In addition, see [Testing an Install](docs/testing-an-install.md).

* The server is slow to start, is it broken?
  * The server may take 1-3min to start; check the health status of each service with `sudo docker ps`
  * By default, Graphistry has 4 RAPIDS workers (service `etl-server-python`) that perform just-in-time GPU compilation, meaning the first load on each is slow.
  * ... System start and the first visualization load per process might be sped up by ensuring Docker is using a native diff driver (see [performance tuning](docs/performance-tuning.md))
  * ... Subsequent use of those workers are fast for new datasets (code is already compiled), and subsequent reloads of recent datasets are extra fast (cached)

* Can I add extra security layers? Yes -- see the hardening section for configuring areas like TLS, and contact the team for assistance with more custom/experimental layers like SSO

* Can I run on another port? Yes -- modify `docker-compose.yml`'s service `caddy:`, such as for 80 to instead be 8888:
```yml
    ports:
      - 8888:80
    expose:
      - "8888"
```


## Further reading

* Plan a deployment
  * Architecture: [Deployment architecture planning guide](docs/deployment-planning.md)
  * Capacity: [Hardware/software requirements](hardware-software.md)
  * Security: [Recommended hardening](docs/configure-security.md), [threat model](docs/threatmodel.md), [authentication](docs/authentication.md)
* Install
  * [Release portal](https://graphistry.zendesk.com/hc/en-us/articles/360033184174) for enterprise admins to download the latest Docker images
  * [Manual Graphistry Installation](docs/manual.md) for non-marketplace / non-hosted: 
  <br>AWS BYOL, Azure BYOL, On-Prem (RHEL/Ubuntu), & Air-Gapped
  * [Nvidia vGPU virtualization support](docs/vGPU.md)
* Configure
  * [System settings](docs/configure.md): 
    <br/>TLS/SSL/HTTPS, performance, logging, backups to disk, multiple proxy layers, and more
      * [Security: Enable auto-TLS and restrict network access](docs/configure-security.md)
      * [Add users](docs/user-creation.md)
      * [AWS Marketplace quickstart](docs/aws_marketplace.md)
      * [Azure Marketplace quickstart](docs/azure_marketplace.md)
  * Content: 
      * [Investigations connectors](docs/configure-investigation.md): Splunk, Neo4j, and more
      * [Investigation templates](docs/templates.md): Save, reuse, link, and embed workflows
      * [Custom pivots](docs/configure-custom-pivots.md): Streamline common investigation steps with simplified UIs
      * [Ontology](docs/configure-ontology.md): Add new types and customize colors, icons, sizes, and more 
      * The [Graphistry Data Bridge](docs/bridge.md): Go between cloud <> on-prem
  * [PyGraphistry and notebooks](docs/configure-pygraphistry.md)

* Maintain
  * [Roadmap](https://github.com/graphistry/graphistry-community/projects/1) and [release notes](https://graphistry.zendesk.com/hc/en-us/articles/360033184174)
  * On unconfigured instance reboots, you may need to first run `sudo systemctl start docker`
  * [Update, backup, and migrate](docs/update-backup-migrate.md)
* Test:
  * [Testing an install](docs/testing-an-install.md)
