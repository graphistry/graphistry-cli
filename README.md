# A CLI for Managing a Graphistry Deployment


This is a toolkit for launching and managing a Graphistry stack on your servers.

Home Page: http://graphistry.com


## Contents
* Quick Start
* Features
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

Ubuntu
------
***Install Graphistry***

    $ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh ubuntu

RHEL/Centos7
------------
Install git
::
    $ sudo yum install -y git

Install Graphistry
::
    $ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh rhel

`detailed instructions`_.

.. _`detailed instructions`: https://github.com/graphistry/graphistry-cli#detailed-installation-instructions

Usage
-----

::

    $ graphistry

Press tab to see options. Run `init` for first configuration & launch.

Features
========

The `graphistry` management cli is written using prompt_toolkit_. It supports commands that:

* Connect to your Graphistry Cloud administrator account
* Assist initial installation and launch
* Download new versions of Graphistry
* Configure your system
* Start and stop your system
* Create bundles for scanning and air-gapped deployment
* Can be used with orchestration systmes like Ansible

These commands can largely be done without the tool, but are easier with them.

Config
------
A config file is automatically created at ``~/.config/graphistry/config`` at first launch.
See the file itself for a description of all available options.


Detailed Installation Instructions:
===================================

The following walks you through launching and configuring your system environment, installing and configuring Graphistry, and launching Graphistry. Additional instructions at the bottom cover air-gapped installations and binary scans.

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
Install Graphistry
::
    $ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh ubuntu

RHEL/Centos7
------------
Install git
::
    $ sudo yum install -y git

Install Graphistry
::
    $ git clone https://github.com/graphistry/graphistry-cli.git && bash graphistry-cli/bootstrap.sh rhel

**Airgapped Bootstrapping**

The above scripts bootstrap the installation of Python3, Docker, CUDA, and Nvidia-Docker for various Linux distributions.
You can install those manually or use ``./bootstrap.sh <ubuntu/rhel>`` that is extracted to the root from your bundle.

The individual steps are broken out into their own scripts in the ``graphistry/bootstrap`` directory.

Once you've bootstrapped, all you need to do is run the ``graphistry`` cli, then use the ``load``, ``config``, and
``launch`` commands consecutively.

Installation:
-------------

1. The above commands will bootstrap your system and get the Graphistry cli ready. This will take a while.
2. After they complete, follow the instructions and run ``graphistry``
3. Now inside the Graphistry prompt, you can hit ``tab`` to see your options, but all you need to do to get Graphistry up and running
is run the ``init`` command and answer the questions.

Additional Commands and Configuration
======================

Starting:
----

From the Graphistry cli, run ``launch``

Stopping:
----

From the Graphistry cli, run ``stop``

Upgrading:
----

From the Graphistry cli, run ``update``. The next time you run ``init``, ``launch``, ``pull``, or ``compile``, the latest version of Graphistry will be used.

Setup SSL:
----

If you have SSL certificates, we recommend installing them: this improves security and enables Graphistry to embed into tools that also use HTTPs.

1. Create folder `ssl/` as a sibling to `deploy`
2. Place files ``ssl_certificate.pem`` and ``ssl_certificate_key.pem`` into folder ``ssl/`` .
3. When running `graphistry` -> `config` (or `graphistry` -> `init`), say "yes" to using SSL

Bundle a Deploy for Scanning and Air-Gapped Deployment:
--------------------------------------------------------
1. See the Linux bootstrapping section for setting up environment dependencies
2. Online system: From the ``graphistry`` cli, type ``compile`` to generate a *.tar.gz, and transfer (alongside the cli) to your offline system.
3. Offline system: Run ``load`` to load bundled containers from another system. We assume Docker, Nvidia-Docker, and Graphistry cli are present in the new system.

Troubleshooting:
======================

Did you have issues with pulling containers and you know they are public? Sometimes `docker-py` gets confused if you have
old containers or are running out of space. Clear out your containers, do a `docker logout` in your terminal and then try again.

Thanks:
======================

A special thanks to `Jonathan Slenders <https://twitter.com/jonathan_s>`_ for
creating `Python Prompt Toolkit <http://github.com/jonathanslenders/python-prompt-toolkit>`_,
which is quite literally the backbone library, that made this app possible.
And the people who made `pgcli <https://github.com/dbcli/pgcli>`_ which I mostly wholesale copied to make this tool

`Click <http://click.pocoo.org/>`_ is used for command line option parsing and printing error messages.

