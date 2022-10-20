# Performance tuning

See also [deployment planning](deployment-planning.md) and [hw/sw planning](../hardware-software.md).

## Monitoring

* Watch resource utilization
  * GPU use via `nvidia-smi`-based compute/memory
  * CPU use via standard tools like `top`, `htop`, and `ps`
  * Network use via `iftop`
  * Check for both memory compute, and network consumption, and by which process 
* Check logs for potential errors
  * System: Standard OS logs
  * App: `docker-compose logs`
* Log level impacts performance
  * TRACE: Slow due to heavy CPU <> GPU traffic
  * DEBUG: Will cause large log volumes that require rotation
  * INFO: May cause large log volumes over time that require rotation

## Hardware provisioning

See also [deployment planning](deployment-planning.md) and [hw/sw planning](hardware-software.md)

### System

Graphistry automatically uses the available resources (see monitoring section), which achieves **vertical scaling**.

* Run one Graphistry install in a server with multiple CPUs and one or more GPUs
* Admins can restrict consumption via docker configurations, such as for noisey and greedy neighbor processes

### Cluster 

For **horizontal scaling**:

* Contact staff for early access to the Kubernetes helm charts and information about their current status
* For occasional bigger launches, you can run multiple API servers by fronting a sticky-session load balancer. This is buggy for prolonged use due to account database inconsistency across instances.

## OS and VM configuration

* Ensure virtualization layers are providing required resources
* Check `docker info` reports `Native Overlay Diff: true`
* Ensure docker downloads, containers, and volumes are somewhere with space
  * Cloud VMs often have massive scratchpads, such as `/mnt` in Azure, which is good for downloads and testing
  * Docker: Modify where containers and their volumes are stored via [daemon.json's graph setting](https://stackoverflow.com/questions/24309526/how-to-change-the-docker-image-installation-directory/34731550#34731550)



## Graphistry application-level configuration

* See below for multi-GPU tuning
* Check `LOG_LEVEL` and `GRAPHISTRY_LOG_LEVEL` (`data/config/custom.env`) is set to `INFO` or `ERROR`
* Add environment variables to `data/config/custom.env` based on available CPU/GPU cores and memory:
  * Default configuration aims to saturate a 1 GB (16 GB RAM) / 8 core (16 GB RAM) system
  * GPU live clustering: `STREAMGL_NUM_WORKERS`, defaults to `4`, recommend 1 per 4GB GPU and 4 GB CPU
  * GPU/CPU analytics:`FORGE_NUM_WORKERS`, defaults to `1`, recommend 1 per 4 GB GPU and 4 GB CPU
  * Experiment with [RMM settings](https://github.com/rapidsai/rmm) in your `data/config/custom.env` for GPU allocations by `forge-etl-python`:
      * `RMM_ALLOCATOR`: `default` or `managed` (default)
      * `RMM_POOL`: `TRUE` (default) or `FALSE`
      * `RMM_INITIAL_POOL_SIZE`: None or # bytes (default: `33554432` for 32MB)
      * `RMM_MAXIMUM_POOL_SIZE`: None or # bytes (default: None, meaning full GPU)
      * `RMM_ENABLE_LOGGING`: `TRUE` or `FALSE` (default)
  * CPU network streaming and limited analytics: `STREAMGL_CPU_NUM_WORKERS`, defaults to `max`, recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS` (GPU sibling)
  * CPU upload handlers: `PM2_MAX_WORKERS`, defaults to `max`, recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS`
  * File sizes:
     * `UPLOAD_MAX_SIZE`: `1M`, `10G`, etc. (Hub default: `200M`, private server default:  `1G`)
     * Use the new Files API: Send compressed data, bigger data with preprocessing, and avoid re-sends
* If oversubscription is due to too many users running clustering, decrease `GRAPH_PLAY_TIMEOUTMS` from one minute, such as 30 seconds (30000 milliseconds)

## Multi-GPU tuning

By default, Graphistry will use all available Nvidia GPUs and CPU cores on a server to spread tasks from concurrent users:

* The GPU-using services are `streamgl-gpu`, `forge-etl-python`, and `dask-cuda-worker`
* Each service used all GPUs by default
* Pick which GPUs a service's workers can access by setting environment variable NVIDIA_VISIBLE_DEVICES
  * Ex: `NVIDIA_VISIBLE_DEVICES=""` <-- no GPUs (CPU-only)
  * Ex: `NVIDIA_VISIBLE_DEVICES=0` <-- GPU 0
  * Ex: `NVIDIA_VISIBLE_DEVICES=0,3` <-- GPUs 0 and 3
  * Every GPU exposed to `forge-etl-python` should also be exposed to `dask-cuda-worker`
* By default, each GPU worker can use any CPU core
  * In general, there should be 4+ CPU cores per GPU
  * Consider matching the CPUs for a GPU worker to the GPU NUMA hierarchy, especially on bigger nodes
* You can further configure `dask-cuda-worker` using [standard settings](https://dask-cuda.readthedocs.io/en/stable/worker.html)
* Services use load balancing strategies like sticky IP sessions
  * Artifical benchmarks may be deceptively reporting non-multi-GPU behavior due to this

We encourage reaching out to staff as part of configuring and testing more advanced configurations.

## Let's chat

Performance can be tricky; we are happy to help via [your preferred communication channel](https://www.graphistry.com/support).
