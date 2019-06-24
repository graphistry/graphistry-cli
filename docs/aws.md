# Graphistry on AWS: Environment Setup Instructions

Graphistry runs on AWS EC2. This document describes initial AWS virtual machine environment setup. From here, proceed to the general Graphistry installation instructions linked below. 

The document assumes light familiarity with how to provision a standard CPU virtual machine in AWS. 

For AWS Marketplace users, instead see [AWS Marketplace Administration](https://github.com/graphistry/graphistry-cli/blob/master/docs/aws_marketplace.md)


Contents:

  1. Pick Linux distribution: Ubuntu 16.04 (Others supported, but not by our nvidia drivers bootstrapper)
  2. Configure instance
  3. General installation

Subsequent reading: [General installation](https://github.com/graphistry/graphistry-cli)



# 1. Pick Linux distribution
Start with one of the following Linux distributions, and configure it using the instructions below under 'Configure instance'.

## Ubuntu 16.04 LTS
  * Available on official AWS launch homepage
  * Find AMI for region https://cloud-images.ubuntu.com/locator/
  * Ex: Amazon AWS us-east-1 xenial 16.04 amd64 hvm-ssd 20180405 ami-6dfe5010 
  * Follow provisioning instructions from AWS install
  * P3.x (Pascal or later): 200 GB, add a name tag, ssh/http/https; use & store an AWS keypair
  * Login: ssh -i ...private_key.pem ubuntu@public.dns

**RHEL, CentOS temporarily not supported by our bootstrapper while conflicting nvidia-docker<>CUDA changes get fixed in the Linux ecosystem**


# 2. Configure instance

* Instance: p*
* 200GB+ RAM
* Security groups: ssh, http, https

# 3. General installation

Proceed to the instructions for [general installation](https://github.com/graphistry/graphistry-cli).
