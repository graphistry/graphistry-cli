A CLI for Managing a Graphistry Deployment
------------------------------------------

Graphistry administration is either via standard `docker-compose` commands or through the Graphistry command-line interface. 

For convenience by cloud users on clean boxes with no Docker, Nvidia drivers, etc., we also provide OS bootstrap scripts. Skip installing the bootstrap if you already have setup your OS for nvidia-docker-2.

Skip installing the CLI if you have a Graphistry tarball.


``graphistry`` supports multiple commands:

* ``login`` Login to Graphistry
* ``pull`` Pull docker containers (only use if no tarball)
* ``help`` Shows all CLI commands
* ``exit`` Leave CLI. Ctrl-C or Ctrl-D works too.

``docker-compose`` supports lifecycle commands:

* `docker-compose up` Starts Graphistry; daemonize via `docker-compose up -d`
* `docker-compose stop` (or ctrl-c) stops Graphistry
* `docker-compose ps` Check status of each service
* `docker-compose exec central curl -s http://localhost:10000/api/internal/provision?text=MY_USER_NAME` generate API key for a developer or notebook user

``docker`` supports manipulation of individual services:
* `docker ps` Lists IDs
*`docker restart <CONTAINER>`
* `docker status`
* `docker logs <CONTAINER>` (or `docker exec -it <CONTAINER>` followed by `cd /var/log`)


Contents
--------

* Quick Start
* Detailed Installation Instructions
   * Prerequisites
   * AWS
   * Linux
   * Installation
* Additional Commands and Configuration
   * Starting and stopping
   * Updating
   * SSL
* Upgrading
* Testing
* Troubleshooting
* Thanks


Quick Start
===========

Bootstrap: Download the CLI and setup your Linux environment
------------------------------------------------------------

For installing docker, docker-compose, CUDA drivers, and nvidia-docker. Skip to testing section if already setup.

**AWS**

* Launch an official AWS Ubuntu 16.04 LTS AMI using a ``g3+``or ``p*`` GPU instance. 
* Use S3AllAccess permissions, and override default parameters for: 200GB disk
* Enable SSH/HTTP/HTTPS in the security groups
* SSH as ``ubuntu@[your ami]``, ``centos@``, or ``ec2-user@``. 

Proceed to the OS-specific instructions below.

**Azure**

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

**Ubuntu 16.04 LTS**
```
    $ git clone https://github.com/graphistry/graphistry-cli.git
    $ bash graphistry-cli/bootstrap.sh ubuntu-cuda9.2
```

**RHEL 7.4 / CentOS 7**
*Note: Temporarily not supported on AWS/Azure*
```
    $ sudo yum install -y git
    $ git clone https://github.com/graphistry/graphistry-cli.git 
    $ bash graphistry-cli/bootstrap.sh rhel
```

**Restart environment**

Log off and back in (full restart not required):  "`$ exit`", "`$ exit`"

**_Warning: Skipping this step means `docker` service may not be available_**


**Test environment**

```
    $ run-parts --regex "test*" graphistry-cli/graphistry/bootstrap/ubuntu-cuda9.2
```

Tests pass for `test-10` through `test-40`.

**Airgapped**

If you were provided a tarball, manually load the containers inside:

```
docker load -i containers.tar
```

Run
-----

* Interactive: `docker-compose up`
* Daemon: `docker-compose up -d`


Detailed Installation Instructions:
===================================

The following walks you through launching and configuring your system environment, installing and configuring Graphistry, and launching Graphistry. Additional instructions for binary scans are available at the bottom.

Prerequisites:
-------------
* Linux (see below AMI versions) with an Nvidia GPU
* Graphistry account and internet connection for initial system download

Cloud:
----------------------

### AWS

See [full AWS installation instructions](https://github.com/graphistry/graphistry-cli/blob/master/docs/aws.md).

### Azure

See [full Azure installation instructions](https://github.com/graphistry/graphistry-cli/blob/master/docs/azure.md).


Linux:
----------------------

*Note: Temporarily, only Ubuntu 16.04 LTS supported on AWS/Azure*

Launch a GPU instance of Graphistry of either RHEL or Ubuntu. See the HW/SW document for recommended system specifications. 

Log into your Graphistry server, install the CLI, and bootstrap system dependencies (docker, docker-compose, CUDA drivers, nvidia-docker). Skip the bootstrap if you have the system dependencies. Skip the CLI if you have the tarball.


### Ubuntu 16.04 LTS

```
    $ git clone https://github.com/graphistry/graphistry-cli.git
    $ bash graphistry-cli/bootstrap.sh ubuntu-cuda9.2
```

### RHEL/Centos7

*Note: Temporarily not supported on AWS/Azure*

```
    $ sudo yum install -y git
    $ git clone https://github.com/graphistry/graphistry-cli.git 
    $ bash graphistry-cli/bootstrap.sh rhel
```



Additional Commands and Configuration
======================

Connectors:
----------
Edit `.env` and restart Graphistry

Passwords:
---------
Edit `.env` and restart Graphistry


Setup SSL:
----------

If you have SSL certificates, we recommend installing them: this improves security and enables Graphistry to embed into tools that also use HTTPs.

1. Edit `~/docker-compose.yml` to enable nginx ssl config (or define your own)
2. Place files `ssl.crt`, `ssl.key`, `ssl_trusted_certificate.pem` into folder ``ssl/`` .
3. Restart Graphistry

Restarting:
-----------

Graphistry automatically restarts in case of errors. In case of manual restart or reboot:

* On reboot, you may need to first run:
  * `sudo systemctl start docker`
  * `sudo service nvidia-docker start`
* If using daemons:
  * `docker-compose restart`
  * `docker-compose stop` and `docker-compose start`
* Otherwise `docker-compose up`


Upgrading:
==========

Your version of Graphistry is determined by your cloud admin account and the version of the Graphistry CLI being used. The overall flow is: stop the running server, remove the old configuration and reinstall the relevant CLI,  configure the system, download any new containers, and launch.

### Update to the latest container: Internet connected

1. Stop the Graphistry server if it is running: `docker-compose stop`
2. Load the new containers (e.g., `docker load -i containers.tar`) 
3. Edit any config (`docker-compose.yml` and `.env`)
4. Restart Graphistry: `docker-compose up` (or `docker-compose up -d`)

You may want to backup `.env`, `.docker-compose.yml`, `.config/*`, `etc/ssl`, and `.pivotdb/*`.


Testing:
========

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



Troubleshooting:
================

Did you have issues with pulling containers and you know they are public? Sometimes `docker-py` gets confused if you have
old containers or are running out of space. Clear out your containers, do a `docker logout` in your terminal and then try again.

Thanks:
=======

A special thanks to `Jonathan Slenders <https://twitter.com/jonathan_s>` for
creating `Python Prompt Toolkit <http://github.com/jonathanslenders/python-prompt-toolkit>`,
which is quite literally the backbone library, that made this app possible.
And the people who made `pgcli <https://github.com/dbcli/pgcli>` which I mostly wholesale copied to make this tool

`Click <http://click.pocoo.org/>` is used for command line option parsing and printing error messages.

