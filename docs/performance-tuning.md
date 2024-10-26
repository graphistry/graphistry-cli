# Performance tuning

See also [deployment planning](deployment-planning.md) and [hw/sw planning](hardware-software.md).

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

Much of the application tuning often comes down to worker counts per service and memory usage guidance

### Quick tips
* See below for multi-GPU tuning
* Check `LOG_LEVEL` and `GRAPHISTRY_LOG_LEVEL` (`data/config/custom.env`) is set to `INFO` or `ERROR`
* Inspect resource consumption during heavy server activity using `docker stats`, `nvidia-smi`, and other primitives 
* If oversubscription is due to too many users running clustering, decrease `GRAPH_PLAY_TIMEOUTMS` from one minute, such as 30 seconds (30000 milliseconds)

### Worker counts

Default configuration aims to saturate a 1 GPU (16 GB RAM) / 8 core (16 GB RAM) system

Add environment variables to `data/config/custom.env` to control:
  * GPU live clustering: `STREAMGL_NUM_WORKERS`, defaults to `4`, recommend 1 per 4GB GPU and 4 GB CPU (service `streamgl-gpu`)
  * GPU/CPU analytics:`FORGE_NUM_WORKERS`, defaults to `4`, recommend 1 per 4 GB GPU and 4 GB CPU (service `forge-etl-python`)
  * CPU visualization: `STREAMGL_CPU_NUM_WORKERS` + `PM2_MAX_WORKERS`, defaults to `4` or `max`, (service `streamgl-viz`)
    * Recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS`
  * Deprecated - CPU upload handlers: `PM2_MAX_WORKERS`, defaults to `max`, recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS`

### RMM GPU settings

RAPIDS-using services will try to use all available GPU RAM and mirror it on the CPU via Nvidia RMM. This includes the visualization services `forge-etl-python` + `dask-cuda-worker`, and the notebook/dashboard services `notebook`, `graph-app-kit-public`, and `graph-app-kit-private`. 

Experiment with [RMM settings](https://github.com/rapidsai/rmm) in your `data/config/custom.env` to control their GPU allocations:
      * `RMM_ALLOCATOR`: `default` or `managed` (default)
      * `RMM_POOL`: `TRUE` (default) or `FALSE`
      * `RMM_INITIAL_POOL_SIZE`: None or # bytes (default: `33554432` for 32MB)
      * `RMM_MAXIMUM_POOL_SIZE`: None or # bytes (default: None, meaning full GPU)
      * `RMM_ENABLE_LOGGING`: `TRUE` or `FALSE` (default)

### Cache size

When files are uploaded, as users access them and run tasks like histograms on them, Graphistry will cache results on the CPU and GPU in controllable ways. This primarily impacts the service `forge-etl-python`, which you may want to increase/decrease memory usage on.

Note that the following sizes are per-worker, so if there are 4 `forge-etl-python` GPU workers and `N_CACHE_GPU_FULL_OVERRIDE=30`, that means 120 cached `TABLE_FETCH_DF` objects on the GPU, 120 cached `TIMEBAR_COMPUTE_TIMEBAR` objects on the GPU, etc.

Edit `data/config/custom.env` to override, and typically use multiples of 4:

```bash
# Cascade for determining each item's cache count max_size:
#  - N_CACHE_<ITEM_NAME>
#  - N_CACHE_{CPU,GPU}_{FULL,SMALL}_OVERRIDE
#  - N_CACHE_{CPU,GPU}_OVERRIDE
#  - Item default
#
# Often most important:
# GPU:
# - N_CACHE_ROUTES_SHAPER_TIMEBAR
# - N_CACHE_ROUTES_SHAPER_HISTOGRAM
# - N_CACHE_ROUTES_SHAPER_SELECT_IDS_IN_GROUP
# - N_CACHE_ARROW_LOADER_FETCH_WARM
# CPU:
# - N_CACHE_ARROW_LOADER_FETCH_VGRAPH
# - N_CACHE_ARROW_LOADER_FETCH_ENCODINGS
# - N_CACHE_ARROW_LOADER_FETCH_HELPER
# - N_CACHE_ARROW_DOWNLOADER_FETCH_UNSHAPED
# - N_CACHE_ARROW_DOWNLOADER_FETCH_SHAPE

#N_CACHE_CPU_OVERRIDE=
#N_CACHE_CPU_FULL_OVERRIDE=
#N_CACHE_CPU_SMALL_OVERRIDE=
#N_CACHE_GPU_OVERRIDE=
#N_CACHE_GPU_FULL_OVERRIDE=
#N_CACHE_GPU_SMALL_OVERRIDE=

# Keep these as 1 or 0; no value to being higher
#N_CACHE_FRAME_TO_PYBYTES=1
#N_CACHE_FRAME_WITH_IDS=1
#N_CACHE_HIST_COMPUTE_HISTOGRAM=1
```

For example, set `N_CACHE_GPU_OVERRIDE=4` to lower all per-worker GPU cache counts, or just `N_CACHE_GPU_FULL_OVERRIDE=4` (default typically about 30) for only the bigger GPU pools (e.g., parsed datasets).

### Network IO

Visualization streaming and limited analytics may be network bound, so on low-bandwidth networks, lower their concurrency levels to fewer users

Counts here largely correspond to `STREAMGL_NUM_WORKERS` and `STREAMGL_CPU_NUM_WORKERS` for the streaming layout service

### Upload size

When pushing datasets via the REST API or users upload via the browser, you can limit amount of data uploaded in a few ways:

     * `UPLOAD_MAX_SIZE`: `1M`, `10G`, etc. (Hub default: `200M`, private server default:  `1G`)
     * Use the new Files API: Send compressed data, bigger data with preprocessing, and avoid re-sends
     * Use compressed formats, like Parquet with Snappy compression


## Multi-GPU tuning

By default, Graphistry will use all available Nvidia GPUs and CPU cores on a server to spread tasks from concurrent users:

* The GPU-using services are `streamgl-gpu`, `forge-etl-python`, and `dask-cuda-worker`
* You may want to increase support CPU worker counts accordingly as well, see above
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
