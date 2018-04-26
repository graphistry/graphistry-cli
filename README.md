A CLI for Managing a Graphistry Deployment
------------------------------------------

The Graphistry command-line interface supports installing, launching, and managing Graphistry. This document also walks through air-gapped deployment concerns such as environment bootstrapping and migrations.

``graphistry`` supports multiple commands:

* ``init`` your initial installation (configure, pull, launch)
* ``login``  to the Graphistry Cloud under your organization's administrator account
* ``config``  your system
* ``launch``  your system
* ``pull``  new versions
* ``compile`` your bundle into a tarball for scanning and air-gapped deployment
* ``load`` a bundled tarball for air-gapped deployment
* ``stop``  your system
* Can be used with orchestration systems like Ansible

These commands can largely be done without the tool, but are easier with them.


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
* Troubleshooting
* Thanks

Quick Start
===========


Bootstrap: Download the CLI and setup your Linux environment
------------------------------------------------------------

**AWS**
Search for the ``graphistry`` public AMI in your region (ex: US-East-1, Oregon). Launch as a ``g3+``or ``p*`` GPU instance  with S3AllAccess permissions, and override default parameters for: 200GB RAM, and enable http/https/ssl in the security groups. SSH as ``ubuntu@[your ami]``.

**Ubuntu**
    $ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh ubuntu

**RHEL/Centos7**
    $ sudo yum install -y git
    $ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh rhel

Run
-----
    $ graphistry

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
Use a Graphistry-provided AMI in your region (search for Graphistry in Public AMIs). Otherwise, start with one of the following Linux distributions, and configure it using the instructions below under 'Linux'.

**Third-Party Base AMI**

We recommend using a Graphistry-provided AMI in your region (search for Graphistry in Public AMIs). Otherwise:

* **Ubuntu 16.04**
  * Find AMI for region https://cloud-images.ubuntu.com/locator/
  * Ex: Amazon AWS us-east-1 xenial 16.04 amd64 hvm-ssd 20180405 ami-6dfe5010 
  * Follow provisioning instructions from AWS install
  * G3 or P2: 200 GB, add a name tag, ssh/http/https; use & store an AWS keypair
  * Login: ssh -i ...private_key.pem ubuntu@public.dns
* **Redhat 7.4 GA**
  * Find AMI for region: https://access.redhat.com/articles/3135091 
  * Ex:  RHEL 7.4 GA
  * ami-c998b6b2	us-east-1	On-Demand	EBS backed image	8/1/2017
  * Follow above AWS Ubuntu instructions, except use ssh username *"ec2-user"*
* **CentOS 7**
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

If you are using a Graphistry-provided AMI, run ``graphistry``. Else, first run through the below Linux instructions.


Linux:
-----

Launch a GPU instance of Graphistry of either RHEL or Ubuntu. See the HW/SW document for recommended system specifications.

Log into your Graphistry server and install the CLI:


Ubuntu
------
***Install Graphistry and launch the CLI***

```
$ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh ubuntu
$ graphistry
```

RHEL/Centos7
------------
**Install git**
```
$ sudo yum install -y git
```

**Install Graphistry and launch the CLI**

```
$ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh rhel
$ graphistry
```
**Airgapped Bootstrapping**

The above scripts bootstrap the installation of Python3, Docker, CUDA, and Nvidia-Docker for various Linux distributions.
You can install those manually or use ``./bootstrap.sh <ubuntu/rhel>`` that is extracted to the root from your bundle.

The individual steps are broken out into their own scripts in the ``graphistry/bootstrap`` directory.

Once you've bootstrapped, run ``graphistry`` and then: ``load``, ``config``, ``launch``. (Instead of ``init``.)


Installation:
-------------

1. The above commands will bootstrap your system and get the Graphistry cli ready. This will take a while.
2. After they complete, follow the instructions and run ``graphistry``
3. Now inside the Graphistry prompt, you can hit ``tab`` to see your options, but all you need to do to get Graphistry up and running is run the ``init`` command and answer the questions. Leave any blank that you are unsure about, and be ready to say which if you find launch issues.


Additional Commands and Configuration
======================

Config
------
A config file is automatically created at ``~/.config/graphistry/config`` at first launch.
See the file itself for a description of all available options. See individual ``*.json`` files for app configurations.


Starting:
---------

From the Graphistry cli, run ``launch``

Stopping:
---------

From the Graphistry cli, run ``stop``

Upgrading:
----------

From the Graphistry cli, run ``update``. The next time you run ``init``, ``launch``, ``pull``, or ``compile``, the latest version of Graphistry will be used.

Setup SSL:
----------

If you have SSL certificates, we recommend installing them: this improves security and enables Graphistry to embed into tools that also use HTTPs.

1. Create folder `ssl/` as a sibling to `deploy`
2. Place files ``ssl_certificate.pem`` and ``ssl_certificate_key.pem`` into folder ``ssl/`` .
3. When running `graphistry` -> `config` (or `graphistry` -> `init`), say "yes" to using SSL

Bundle a Deploy for Scanning and Air-Gapped Deployment:
--------------------------------------------------------

A full Graphistry deployment involves several systems:

* Bootstrapped environment (see above): Docker, Nvidia-Docker, Python3, ...
* Graphistry CLI (Python 3 wheel)
* Graphistry itself (Docker containers)
* Graphistry configuration (.config and .json) <-- can be generated on the air-gapped system

The process is:
1. Download a tarball from Graphistry as a password-protected URL, or generated via the CLI on an internet-connected device
2. Setup the airgapped server: perform the above bootstrap processes and install the tarball
3. Reconfigure the Graphistry installation for the air-gapped server and launch it

**Generate a Tarball (Internet-connected)**

Either download a tarball from your Graphistry account, or on an internet-connected device, generate a tarball:

1. See the Linux bootstrapping section for setting up environment dependencies
2. Start the CLI: ``graphistry``
3. From the CLI, run:  ``login`` ; ``pull`` ; ``compile``

You will now have a ``*.tar.gz`` that contains binaries (CLI + Graphistry) and any existing configuration (.config, .json).

**Load a Tarball (Airgapped)**

From a bootstrapped environment (Docker, Python3, Nvidia-Docker, ... see above):

1. Decompress: ``tar -xvzf my_graphistry.tar.gz``
2. Start the CLI: ``graphistry``
3. From the CLI, run: ``load`` ; ``config`` ; ``launch``

The ``config`` call will generate details specific to the airgapped deployment and store them in ``.config`` and ``.json`` files. 

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

