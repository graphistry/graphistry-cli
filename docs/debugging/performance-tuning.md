# Performance tuning

See also [deployment planning](../planning/deployment-planning.md) and [hw/sw planning](../planning/hardware-software.md).

## Monitoring

* Watch resource utilization
  * GPU use via `nvidia-smi`-based compute/memory
  * CPU use via standard tools like `top`, `htop`, and `ps`
  * Network use via `iftop`
  * Check for both memory compute, and network consumption, and by which process 
* Check logs for potential errors
  * System: Standard OS logs
  * App: `docker compose logs`
* Log level impacts performance
  * TRACE: Slow due to heavy CPU <> GPU traffic
  * DEBUG: Will cause large log volumes that require rotation
  * INFO: May cause large log volumes over time that require rotation

## Hardware provisioning

See also [deployment planning](../planning/deployment-planning.md) and [hw/sw planning](../planning/hardware-software.md)

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

### GPU Memory Watcher

Optional safety feature that monitors GPU memory usage and can automatically terminate runaway processes before they cause OOM (Out of Memory) errors. This is particularly useful for production deployments where uncontrolled memory growth could impact system stability.

**Enable the watcher** by adding to `data/config/custom.env`:

```bash
FEP_GPU_WATCHER_ENABLED=1
```

**Configuration options** (all optional, showing defaults):

| Variable | Description | Default |
|----------|-------------|---------|
| `FEP_GPU_WATCHER_ENABLED` | Enable GPU memory monitoring | disabled |
| `FEP_GPU_WATCHER_POLL_SECONDS` | How often to check GPU memory | 15 |
| `FEP_GPU_WATCHER_HEARTBEAT_SECONDS` | Log heartbeat interval (0 = disabled) | disabled |
| `FEP_GPU_WATCHER_WARN_THRESHOLD` | Log warning when memory exceeds this | disabled |
| `FEP_GPU_WATCHER_KILL_THRESHOLD` | Start deferred kill process | disabled |
| `FEP_GPU_WATCHER_IDLE_THRESHOLD` | Kill if still above this after defer period | disabled |
| `FEP_GPU_WATCHER_KILL_DEFER_SECONDS` | Wait time before killing (allows job completion) | 300 |
| `FEP_GPU_WATCHER_EMERGENCY_THRESHOLD` | Immediate kill, no defer period | disabled |

Thresholds can be specified as:
- **Percentage**: `70%`, `90%`, `95%`
- **Absolute MB**: `8192MB`, `16384MB`

**Example production configuration:**

```bash
# Enable GPU memory watcher with production thresholds
FEP_GPU_WATCHER_ENABLED=1
FEP_GPU_WATCHER_POLL_SECONDS=30
FEP_GPU_WATCHER_HEARTBEAT_SECONDS=300
FEP_GPU_WATCHER_WARN_THRESHOLD=70%
FEP_GPU_WATCHER_KILL_THRESHOLD=90%
FEP_GPU_WATCHER_IDLE_THRESHOLD=60%
FEP_GPU_WATCHER_KILL_DEFER_SECONDS=300
FEP_GPU_WATCHER_EMERGENCY_THRESHOLD=95%
```

This configuration:
- Checks memory every 30 seconds
- Logs heartbeat every 5 minutes
- Warns at 70% memory usage
- Starts deferred kill at 90%, waiting 5 minutes for job completion
- Kills immediately at 95% (emergency)

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

By default, Graphistry will use all available Nvidia GPUs and CPU cores on a server to spread tasks from concurrent users.

### GPU Configuration Wizard

The easiest way to configure multi-GPU settings is using the GPU configuration wizard:

```bash
# Interactive mode - displays recommended settings
./etc/scripts/gpu-config-wizard.sh

# Export mode - writes to custom.env
./etc/scripts/gpu-config-wizard.sh -E ./data/config/custom.env

# Use hardware preset (140+ available)
./etc/scripts/gpu-config-wizard.sh -p aws-p3-8xlarge
./etc/scripts/gpu-config-wizard.sh -p dgx-a100
```

See [GPU Configuration Wizard](../tools/gpu-config-wizard.md) for full documentation and preset list.

### Per-Service GPU Assignment

For advanced multi-GPU configurations, you can assign specific GPUs to specific services via `data/config/custom.env`.

**Fallback chain** for each service:
1. Service-specific variable (e.g., `FEP_CUDA_VISIBLE_DEVICES`)
2. Global `CUDA_VISIBLE_DEVICES`
3. Default: GPU 0

**Service-specific GPU variables:**

| Variable | Service |
|----------|---------|
| `FEP_CUDA_VISIBLE_DEVICES` | forge-etl-python |
| `STREAMGL_GPU_CUDA_VISIBLE_DEVICES` | streamgl-gpu |
| `DCW_CUDA_VISIBLE_DEVICES` | dask-cuda-worker |
| `DASK_SCHEDULER_CUDA_VISIBLE_DEVICES` | dask-scheduler |
| `GAK_PUBLIC_CUDA_VISIBLE_DEVICES` | graph-app-kit-public |
| `GAK_PRIVATE_CUDA_VISIBLE_DEVICES` | graph-app-kit-private |
| `NOTEBOOK_CUDA_VISIBLE_DEVICES` | notebook |

**Format support:**
- Integer format: `0,1,2,3` (standard CUDA format)
- UUID format: `GPU-xxx,GPU-yyy` (VMware/Nutanix/MIG environments)
- Mixed format NOT supported

**Examples:**

```bash
# Isolate GPU workloads (dedicated GPUs per service)
FEP_CUDA_VISIBLE_DEVICES=0
STREAMGL_GPU_CUDA_VISIBLE_DEVICES=1

# Share all GPUs (round-robin assignment)
CUDA_VISIBLE_DEVICES=0,1,2,3

# VMware/Nutanix/MIG environments
CUDA_VISIBLE_DEVICES=GPU-abc123,GPU-def456
```

### Multi-Worker Configuration

Configure worker counts to match your GPU configuration:

| Variable | Description | Default |
|----------|-------------|---------|
| `FORGE_NUM_WORKERS` | forge-etl-python Hypercorn workers | 4 |
| `STREAMGL_NUM_WORKERS` | streamgl-gpu workers | 4 |
| `DASK_NUM_WORKERS` | dask-cuda-worker instances | 1 |

**GPU underutilization policy** (matches PyTorch/dask-cuda behavior):
- Workers < GPUs: Service logs WARNING, unused GPUs remain idle
- Workers > GPUs: Round-robin assignment distributes workers evenly
- Workers = GPUs: One-to-one assignment (optimal)

**Round-robin GPU assignment examples:**
- 2 GPUs, 5 workers → GPU 0 gets workers [0,2,4], GPU 1 gets [1,3]
- 4 GPUs, 1 worker → GPU 0 gets worker [0], GPUs [1,2,3] idle

**Recommended configurations:**

```bash
# Dual GPU setup
CUDA_VISIBLE_DEVICES=0,1
FORGE_NUM_WORKERS=8
STREAMGL_NUM_WORKERS=8
DASK_NUM_WORKERS=2

# Quad GPU setup
CUDA_VISIBLE_DEVICES=0,1,2,3
FORGE_NUM_WORKERS=16
STREAMGL_NUM_WORKERS=16
DASK_NUM_WORKERS=4
```

### General Multi-GPU Guidelines

* The GPU-using services are `streamgl-gpu`, `forge-etl-python`, and `dask-cuda-worker`
* You may want to increase CPU worker counts accordingly as well (see above)
* Every GPU exposed to `forge-etl-python` should also be exposed to `dask-cuda-worker`
* By default, each GPU worker can use any CPU core
  * In general, there should be 4+ CPU cores per GPU
  * Consider matching the CPUs for a GPU worker to the GPU NUMA hierarchy, especially on bigger nodes
* You can further configure `dask-cuda-worker` using [standard settings](https://dask-cuda.readthedocs.io/en/stable/worker.html)
* Services use load balancing strategies like sticky IP sessions
  * Artificial benchmarks may be deceptively reporting non-multi-GPU behavior due to this

We encourage reaching out to staff as part of configuring and testing more advanced configurations.

## Let's chat

Performance can be tricky; we are happy to help via [your preferred communication channel](https://www.graphistry.com/support).
