A CLI for Managing a Graphistry Deployment
------------------------------------------

The Graphistry command-line interface supports installing, launching, and managing Graphistry. This document also walks through air-gapped deployment concerns such as environment bootstrapping and migrations.

``graphistry`` supports multiple commands:


* ``init`` Download, configure, and launch Graphistry
* ``compile`` Generate dist/graphistry.tar.gz
* ``compile_with_config`` Generate dist/graphistry.tar.gz and include local configuration
* ``config`` Configure Graphistry relative to latest Graphistry online baseline
* ``config_offline`` Configure Graphistry relative to offline baseline
* ``exit`` Leave application. Ctrl-C or Ctrl-D works too.
* ``keygen`` Create API key token
* ``help`` Shows all CLI commands
* ``launch`` Launch Graphistry based on local containers
* ``load`` Load Graphistry from Container Archive
* ``login`` Login to Graphistry
* ``pull`` Pull docker containers
* ``stop`` Stop All Graphistry Containers

Run non-interactive commands with ``-c``, such as ``graphistry -c stop``.


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
   * Bundling for scanning and air-gapped deployment
* Upgrading
* Testing
* Troubleshooting
* Thanks

Quick Start
===========


Bootstrap: Download the CLI and setup your Linux environment
------------------------------------------------------------

**AWS**

* Launch an official AWS Ubuntu/RHEL/Centos AMI using a ``g3+``or ``p*`` GPU instance. 
* Use S3AllAccess permissions, and override default parameters for: 200GB RAM
* Enable SSH/HTTP/HTTPS in the security groups
* SSH as ``ubuntu@[your ami]``, ``centos@``, or ``ec2-user@``. 

Proceed to the OS-specific instructions below.

**Ubuntu 16.04**
```
    $ git clone https://github.com/graphistry/graphistry-cli.git
    $ bash graphistry-cli/bootstrap.sh ubuntu
```

**RHEL 7.4 / CentOS 7**
```
    $ sudo yum install -y git
    $ git clone https://github.com/graphistry/graphistry-cli.git 
    $ bash graphistry-cli/bootstrap.sh rhel
```

Log off and back in (full restart not required.)

Run
-----
```
    $ graphistry
```

* Press tab to see options
* Run ``init`` for streamlined initial configuration & launch
* See below for SSL setup, which we recommend for use with notebooks, embedding in web apps, and overall security.
* For subsequent use, run ``launch`` and ``stop``


Detailed Installation Instructions:
===================================

The following walks you through launching and configuring your system environment, installing and configuring Graphistry, and launching Graphistry. Additional instructions for air-gapped installation and binary scans are available at the bottom.

Prerequisites:
-------------
* Linux (see below AMI versions) with an Nvidia GPU
* Graphistry account and internet connection for initial system download
* For air-gapped, see the Linux bootstrap dependencies section

AWS:
-------------

**Instance**
Start with one of the following Linux distributions, and configure it using the instructions below under 'Instance settings'.

* **Ubuntu 16.04**
  * Available on official AWS launch homepage
  * Find AMI for region https://cloud-images.ubuntu.com/locator/
  * Ex: Amazon AWS us-east-1 xenial 16.04 amd64 hvm-ssd 20180405 ami-6dfe5010 
  * Follow provisioning instructions from AWS install
  * G3 or P2: 200 GB, add a name tag, ssh/http/https; use & store an AWS keypair
  * Login: ssh -i ...private_key.pem ubuntu@public.dns
* **Redhat 7.4 GA**
  * Available on official AWS launch homepage
  * Find AMI for region: https://access.redhat.com/articles/3135091 
  * Ex:  RHEL 7.4 GA
  * ami-c998b6b2	us-east-1	On-Demand	EBS backed image	8/1/2017
  * Follow above AWS Ubuntu instructions, except use ssh username *"ec2-user"*
* **CentOS 7**
  * Available on official AWS launch homepage
  * Find AMI for region: https://wiki.centos.org/Cloud/AWS
  * Ex: CentOS 1803_01 
  * CentOS Linux 7 1801_01 2018-Jan-14 us-east-1 ami-4bf3d731 x86_64 HVM EBS
  * Follow above AWS Ubuntu instructions, except use ssh username *"centos"*

**Instance Settings**

* S3 credentials
  * Services → Security & Identity → IAM → users → security credentials → create new access key
    * Permissions tab: AmazonS3FullAccess
  * Save access ID, key for later use
* Instance: g3+ or p*
* 200GB+ RAM
* Security groups: ssh, http, https

**Setup**

Continue to the Linux instructions below.


Linux (Non-Airgapped):
----------------------

Launch a GPU instance of Graphistry of either RHEL or Ubuntu. See the HW/SW document for recommended system specifications.

Log into your Graphistry server and install the CLI:


### Ubuntu

```
$ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh ubuntu
```

### RHEL/Centos7


```
$ sudo yum install -y git
$ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh rhel
```

Airgapped
---------


### Bootstrapping

The above scripts bootstrap the installation of Python3, Docker, CUDA, and Nvidia-Docker for various Linux distributions.
You can install those manually or use ``./bootstrap.sh <ubuntu/rhel>`` that is extracted to the root from your bundle.

The individual steps are broken out into their own scripts in the ``graphistry/bootstrap`` directory.

### Transfer, configure, & launch

1. If you do not have a large container file, generate it. Run ``graphistry`` and then: ``init``. After, ``compile``.

2. Move the container to the airgapped system, and bootstrap the system. (See scripts used above.)

3. Run ``graphistry`` and then: ``load``, ``config_offline``, and then ``launch``.


Installation:
-------------

1. The above commands will bootstrap your system and get the Graphistry cli ready. This will take a while.
2. After they complete, follow the instructions and run ``graphistry``
3. Now inside the Graphistry prompt, you can hit ``tab`` to see your options, but all you need to do to get Graphistry up and running is run the ``init`` command and answer the questions. Leave any blank that you are unsure about, and be ready to say which if you find launch issues.


Additional Commands and Configuration
======================


Setup SSL:
----------

If you have SSL certificates, we recommend installing them: this improves security and enables Graphistry to embed into tools that also use HTTPs.

1. Create folder `ssl/` as a sibling to `deploy`
2. Place files ``ssl_certificate.pem`` and ``ssl_certificate_key.pem`` into folder ``ssl/`` .
3. Restart Graphistry

Bundle a Deploy for Scanning and Air-Gapped Deployment:
--------------------------------------------------------

A full Graphistry deployment involves several systems:

* Bootstrapped environment (see above): Docker, Nvidia-Docker, Python3, ...
* Graphistry CLI (Python 3 wheel)
* Graphistry itself (Docker containers)
* Graphistry configuration (~/.config/graphistry/* and *.json) <-- generate on the final (airgapped) system

The process is:
1. Download a tarball from Graphistry as a password-protected URL, or generated via the CLI on an internet-connected device
2. Setup the airgapped server: perform the above bootstrap processes and install the tarball
3. Configure the Graphistry installation for the air-gapped server and launch it

**Generate a Tarball (Internet-connected)**

Either download a tarball from your Graphistry account, or generate one from scratch:

1. See the Linux bootstrapping section for setting up environment dependencies
2. Start the CLI: ``graphistry``
3. From the CLI, run:  ``init`` and then ``compile``

You will now have the file ``dist/graphistry.tar.gz`` that contains binaries (CLI + Graphistry) and none of the instance-specific configuration files or data.

**Load a Tarball (Airgapped)**

From a bootstrapped environment (Docker, Python3, Nvidia-Docker, ... see above):

1. Decompress ``tar -xvzf graphistry942.tar.gz`` into ``releases/942`` 
2. Install the CLI corresponding to the new container:
```
    $ cd releases/942/graphistry-cli
    $ python3.6 setup.py install
```
3. Load the container, configure it, and launch it:
```
    $ cd .. ### containers.tar should be in this folder
    $ graphistry
    >  config_offline
    >  load
    >  launch
```    

You can skip the ``config_offline`` step if the transferred file included sufficient system configurations, such as through correct use of ``compile_with_config`` or through orchestration-provision configuration.


Upgrading:
==========

Your version of Graphistry is determined by your cloud admin account and the version of the Graphistry CLI being used. The overall flow is: stop the running server, remove the old configuration and reinstall the relevant CLI,  configure the system, download any new containers, and launch.

### Update to the latest container: Internet connected

1. Stop the Graphistry server if it is running
```
    $ graphistry -c stop
```

2. Update the CLI
```
    $ cd graphistry-cli
    $ git pull
    $ pip3 uninstall graphistry
    $ python3.6 setup.py clean
    $ pythpn3.6 setup.py install
```    

3. Update Graphistry and restart
```
    $ rm -rf ~/.config ##### Backup this folder and *.json
    $ graphistry
    >   pull
    >   config
    >   load
    >   launch
```    


### Update to the latest container: Airgapped

1. Copy the latest container to your system, e.g., `graphistry/releases/942`
2. Stop Graphistry if it is running: 
```
    $ graphistry -c stop
```

3. Update the CLI
```
    $ cd graphistry-cli
    $ pip3 uninstall graphistry
    $ python3.6 setup.py clean
    $ pythpn3.6 setup.py install
```    

4. Reconfigure, update, and relaunch Graphistry
```
    $ cd .. # containers.tar should be in this folder
    $ rm -rf ~/.config ##### Backup this folder and *.json
    $ graphistry
    >    config
    >    load
    >    launch
```    

Testing:
========

* Installation repositories are accessible:
  * ping www.github.com
  * ping shipyard.graphistry.com
  * ping us.gcr.io
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
  * ``site.com/worker/healthcheck``
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

