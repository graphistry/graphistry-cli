# Graphistry on Azure: Environment Setup Instructions

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

* **Minimal GPU type**: NC6 (hdd) in your region
* **Maximal GPU type**: N-Series, see general documentation for sizing considerations

### Testing if you already have GPU quota

Go through the **Start a new GPU virtual machine**, then tear it down if successful

### Requesting Azure for GPU Quota

For each location in which you want to run Graphistry:

1. Start help ticket: `? (Help)` -> `Help + support` ->  `New support request`
2. Fill out ticket
  1. **Basics**: `Quota` -> `<Your Subscription>` -> `Compute (cores/vCPUs)` -> `Next`
  2. **Problem**: Specify location/SKU, e.g., `West US 2` or `East US` for `NC Series`
  3. **Contact Information**: Fill out and submit

Expect 1-3 days based on your requested `Severity` rating and who Azure assigns to your ticket

## 1. Start a new GPU virtual machine

See general installation instructions for currently supported Linux versions. RHEL/CentOS/Ubuntu are all supported.

1. `Virtual machines` -> `Create virtual machine`
2. `RHel (ex: 7.4)` or `Ubuntu (ex: 18.04 LTS)`
3. **Basics**: As desired; make sure can login, such as by SSH public key; needs to be a region with GPU quota
4. **Size**: GPU of all disk types, e.g., NC6 (hdd) is cheapest for development
5. **Settings**: Open ports for administration (SSH) and usage (HTTP, HTTPS)
6. **Summary**: Should say “`Validation passed`” at the top -> visually audit settings + hit `Create`
7. Test login; see SSH command at `Overview` -> `Connect` -> `Login using VM Account`


## 2. Proceed to general Graphistry installation

Login to your instance (see **Test login** above) and use the instructions for [general installation](https://github.com/graphistry/graphistry-cli).

For steps involving an IP address, see needed IP value at Azure console in `Overview` -> `Public IP address`

