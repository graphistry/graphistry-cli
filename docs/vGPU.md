# Virtual GPU Support

Graphistry is designed to run on virtual GPUs using Nvidia's vGPU capabilities. This may simplify administration, encourage additional privacy modes, and improve isolation. It is tested on Nutanix, Vmware, and whatever is used by the major cloud providers.

If you are installing on such a system, we are happy to help, so please reach out.

## Architectural considerations: You may not want vGPUs

We recommend checking whether you want *baremetal OS*, *hypervisor with a passthrough GPU driver*, or *hypervisor with a vGPU driver*.

A *baremetal OS* (no hypervisor) or *passthrough driver* (hypervisor with non-vGPU driver) configuration may be sufficient, meaning you can skip the complexity of using vGPU drivers and licensing:

* Hypervisors: If only 1 dedicated GPU application, or multiple applications running in the same guest OS, you can expose it in passthrough mode
* Scaling users through multiple GPUs:
  * Graphistry already automatically uses all GPUs exposed to it, primarily for scaling to more user sessions
  * New APIs are starting to use multi-GPUs for acceleration as well
* Multiple Graphistry installs
  * You can launch concurrent instances of Graphistry using docker: `docker-compose up -p my_unique_namespace_123`
  * You can configure docker to use different GPUs or share the same ones
* Isolate Graphistry from other GPU software
  * Docker allows picking which GPUs + CPUs are used
  * ... For both sharing and isolation
* Nvidia vGPUs do not yet support Uniform CPU/GPU memory sharing, which causes RAPIDS processes to crash on bigger-than-GPU memory use instead of transparently spilling

Longer-term, Graphistry is aiming to push most/all GPU use to [Dask](https://docs.dask.org/en/latest/gpu.html), which adds even more flexibility for resource sharing.

## GPU Virtualization configuration planning

Plan licensing and driver versons first, as mistakes may require starting over.

Most likely, you'll want vGPU profile 8Q with vGPU 10.2 -- vGPU 11.0 drivers:

**GPU Driver**

You will install a hypervisor GPU driver in the hypervisor and a guest OS GPU driver in the guest OS:

* The hypervisor+guest GPU driver pair should be from [the same vGPU family](https://docs.nvidia.com/grid/index.html)

* The driver's CUDA version must be [RAPIDS-compatible](https://rapids.ai/start.html): 10.2 -- 11.0 at time of writing

**Virtualization features**: C (vCS)

Nvidia vGPUs have different labels (A, B, C, Q, ...) that correspond with enabled features.

Only C (vCS) and Q (Quadro vDWS) support OpenCL/CUDA. The compute profile (C) is intended for compute workloads like Graphistry. See [official NVIDIA CUDA Toolkit and OpenCL Support on NVIDIA vGPU Software](https://docs.nvidia.com/grid/latest/grid-vgpu-user-guide/index.html#cuda-open-cl-support-vgpu).

**Virtualization type**: Logical (not MIG)

Only one kind of vGPU virtualization currently works with Nvidia RAPIDS:

1. Supported - Logical time and memory sliced: Nvidia RAPIDS-compatible vGPUs are for 10.2 - 11.0 . Each vGPU gets time-sliced and a maximum amount of memory.

2. Unsupported - MIG (physical virtualization): vGPU 11.1+ supports more true isolation of GPU cores and memory... but Nvidia RAPIDS does not yet officially work on MIGs.

**Size**: 2 or 8

Each GPU can be split into homogenous sizes. Ex: `1 x 8Q = 8Q` and `4 x 2Q = 8Q`. You may be able to oversubscribe, e.g., `4 x 4Q = 16Q`.

In the case of multi-GPU systems, you can use different partition sizes on different GPUs. Ex: `(1 x 8Q) + (4 x 2Q)`.

## vGPU Software setup

Supporting vGPUs means setting up a Nvidia license manager server, GPU-capable hypervisor, a GPU-capable guest OS, and making them work together. Almost all other environment configuration is the same as regular self-hosted Graphistry setup.

There is also a 1 line change for making Graphistry work with vGPUs.

#### Licensing server and license

Setup an Nvidia licensing server and use it to generate and download a license. It must stay on while using your vGPU as the license gets dynamically checked.

Unlicensed GPUs will appear under `nvidia-smi` and be marked as unlicensed in `nvidia-smi -q`, but fail upon use with CUDA.

If you have a license server but cannot use it to generate a license, you may be able to [receive a time/account-limited evaluation license at nvidia.com]( https://www.nvidia.com/object/nvidia-enterprise-account.html).


#### Hyperviser

Install hypervisor GPU drivers from the vGPU software version

#### Guest OS

Install guest OS GPU drivers from the vGPU software version

[Configure a local license file](https://docs.nvidia.com/grid/latest/grid-licensing-user-guide/index.html#licensing-grid-software-linux-config-file) at `/etc/nvidia/gridd.conf`. Take care to specify vGPU profile vCS (C) / Quadro vDWS (Q) and the right license manager server. Restart the local daemon via `sudo service nvidia-gridd restart`. 

To confirm license activation, check the license status in `nvidia-smi -q` and debug logs (`sudo grep gridd /var/log/messages`)

#### Graphistry

Set `RMM_ALLOCATOR=default` in your `data/config/custom.env` to avoid relying on CUDA Unified Memory for handling bigger-than-memory workloads, which Nvidia vGPUs do not currently support.

## Hyperviser-specific options

See official docs and support forums for guidance specific to your hypervisor.

### Nutanix

Follow the standard Graphistry + vGPU instructions

Helpful links and configurations:

* Drivers: Download a hypervisor + guest OS driver pair from [an Nvidia.com vGPU account](https://nvid.nvidia.com/siteminderagent/forms/login.fcc) that comes with your hardware purchase. Nutanix does not provide the drivers.
* OS: Ubuntu 18.04 LTS (plain). Do **not** use the listed Snap-based add-on for Docker.
* Docs: Check [main Nutanix.com Nvidia docs](https://portal.nutanix.com/page/documents/details?targetId=AHV-Admin-Guide-v5_19:ahv-gpu-support-on-ahv-c.html) and [supporting Nvidia.com Nutanux docs](https://docs.nvidia.com/grid/10.0/grid-vgpu-release-notes-nutanix-ahv/index.html)



## Testing

Typical checks:

### Hypevisor

* `nvidia-smi` should report a GPU of the expected driver version

### Guest OS

* GPU: `nvidia-smi` should report a GPU of the expected driver version
* License: Nvidia logs: `sudo grep gridd /var/log/messages`

### Hypervisor
* See regular Graphistry testing docs, especially around docker GPU configuration

## Common errors

* CUDA-incapable vGPU profile
* No GPU driver
* RAPIDS-incompatible GPU driver version
* Unlicensed GPU
* License server is down
* No Docker GPU runtime
* Docker GPU runtime not set as default (`docker info` and `/etc/docker/daemon.json`)



