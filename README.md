A CLI for Managing a Graphistry Deployment
------------------------------------------

The Graphistry command-line interface supports installing, launching, and managing Graphistry. See the airgapped mode document for installation in airgapped settings.

``graphistry`` supports multiple commands:


* ``init`` Download, configure, and launch Graphistry
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

The following walks you through launching and configuring your system environment, installing and configuring Graphistry, and launching Graphistry. Additional instructions for binary scans are available at the bottom.

Prerequisites:
-------------
* Linux (see below AMI versions) with an Nvidia GPU
* Graphistry account and internet connection for initial system download

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

* Instance: g3+ or p*
* 200GB+ RAM
* Security groups: ssh, http, https

**Setup**

Continue to the Linux instructions below.


Linux:
----------------------

Launch a GPU instance of Graphistry of either RHEL or Ubuntu. See the HW/SW document for recommended system specifications.

Log into your Graphistry server and install the CLI:


### Ubuntu

```
    $ git clone https://github.com/graphistry/graphistry-cli.git
    $ bash graphistry-cli/bootstrap.sh ubuntu
```

### RHEL/Centos7


```
    $ sudo yum install -y git
    $ git clone https://github.com/graphistry/graphistry-cli.git 
    $ bash graphistry-cli/bootstrap.sh rhel
```



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
    >   config_offline
    >   load
    >   launch
```    
Been ``load`` and ``launch``, you may want to load saved values from your backed up ``.config/`` and ``*.json`` into the generated ones.


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

