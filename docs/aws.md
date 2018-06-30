# Graphistry on AWS: Environment Setup Instructions

Graphistry runs on AWS EC2. This document describes initial AWS virtual machine environment setup. From here, proceed to the general Graphistry installation instructions linked below. 

The document assumes light familiarity with how to provision a standard CPU virtual machine in AWS. 


Contents:

  1. Pick Linux distribution
    Ubuntu
    Redhat
    CentOS
  2. Configure instance
  3. General installation

Subsequent reading: [General installation](https://github.com/graphistry/graphistry-cli)



# 1. Pick Linux distribution
Start with one of the following Linux distributions, and configure it using the instructions below under 'Configure instance'.

## Ubuntu 16.04
  * Available on official AWS launch homepage
  * Find AMI for region https://cloud-images.ubuntu.com/locator/
  * Ex: Amazon AWS us-east-1 xenial 16.04 amd64 hvm-ssd 20180405 ami-6dfe5010 
  * Follow provisioning instructions from AWS install
  * G3 or P2: 200 GB, add a name tag, ssh/http/https; use & store an AWS keypair
  * Login: ssh -i ...private_key.pem ubuntu@public.dns

## Redhat 7.4 GA
  * Available on official AWS launch homepage
  * Find AMI for region: https://access.redhat.com/articles/3135091 
  * Ex:  RHEL 7.4 GA
  * ami-c998b6b2	us-east-1	On-Demand	EBS backed image	8/1/2017
  * Follow above AWS Ubuntu instructions, except use ssh username *"ec2-user"*

## CentOS 7
  * Available on official AWS launch homepage
  * Find AMI for region: https://wiki.centos.org/Cloud/AWS
  * Ex: CentOS 1803_01 
  * CentOS Linux 7 1801_01 2018-Jan-14 us-east-1 ami-4bf3d731 x86_64 HVM EBS
  * Follow above AWS Ubuntu instructions, except use ssh username *"centos"*

# 2. Configure instance

* Instance: g3+ or p*
* 200GB+ RAM
* Security groups: ssh, http, https

# 3. General installation

Proceed to the instructions for [general installation](https://github.com/graphistry/graphistry-cli).
