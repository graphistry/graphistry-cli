# Graphistry on Azure: Manual Environment Setup Instructions


**DEPRECATION WARNING**: 

Get started more quickly and securely with [Graphistry in Azure Marketplace](azure_marketplace.md).

We no longer recommend manually installing drivers via the original Graphistry-maintained bootstrap scripts. Instead, we now recommend using [Graphistry in Azure Marketplace](azure_marketplace.md) which has been preconfigured, and for advanced manual enterprise users, to use the [Nvidia GPU Container (Ubuntu) "Nvidia NGC" base image](https://docs.nvidia.com/ngc/ngc-azure-vmi-release-notes/index.html).


# Deprecated instructions

Graphistry runs on Azure. This document describes initial Azure virtual machine environment setup. From here, proceed to the general Graphistry installation instructions linked below. 

The document assumes light familiarity with how to provision a standard CPU virtual machine in Azure. 


Contents:

  * Prerequisites: Azure GPU Quota
    * Testing if you already have GPU Quota
    * Requesting Azure for GPU Quota
  1. Start a new GPU virtual machine
  2. Proceed to general Graphistry installation

Subsequent reading: [General installation](https://github.com/graphistry/graphistry-cli)


## Prerequisites: Azure GPU Quota
You may need to make quota requests to add GPUs to each of your intended locations:

* **Minimal GPU type**: NC6v2 (hdd) in your region
* **Maximal GPU type**: N-Series, see general documentation for sizing considerations

### Testing if you already have GPU quota

Go through the **Start a new GPU virtual machine**, then tear it down if successful

### Requesting Azure for GPU Quota

For each location in which you want to run Graphistry:

1. Start help ticket: `? (Help)` -> `Help + support` ->  `New support request`
2. Fill out ticket
  1. **Basics**: `Quota` -> `<Your Subscription>` -> `Compute (cores/vCPUs)` -> `Next`
  2. **Problem**: Specify location/SKU, e.g., `West US 2` or `East US` for `NCv2+ Series` and `ND+ Series`
  3. **Contact Information**: Fill out and submit

Expect 1-3 days based on your requested `Severity` rating and who Azure assigns to your ticket

## 1. Start a new GPU virtual machine

See general installation instructions for currently supported Linux versions (subject to above Azure restrictions and general support restrictions.)

1. **Virtual machines** -> `Create virtual machine`
2. **Ubuntu 16.04 LTS** Please let us know if another OS is required
3. **Basics**: As desired; make sure can login, such as by SSH public key; needs to be a region with GPU quota
4. **Size**: GPU of all disk types, e.g., NC6v2 (hdd) is cheapest for development
5. **Settings**: Open ports for administration (SSH) and usage (HTTP, HTTPS)
6. **Summary**: Should say “`Validation passed`” at the top -> visually audit settings + hit `Create`

## 2. Confirm proper instance

1. Test login; see SSH command at `Overview` -> `Connect` -> `Login using VM Account`
2. Check to make sure GPU is attached:

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



## 3. Proceed to general Graphistry installation

Login to your instance (see **Test login** above) and use the instructions for [general installation](https://github.com/graphistry/graphistry-cli).

For steps involving an IP address, see needed IP value at Azure console in `Overview` -> `Public IP address`

Install docker-compose:

```
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

NGC already sets the default docker runtime to nvidia for you (`/etc/docker/daemon.json`).

From here, you can perform a general installation.
