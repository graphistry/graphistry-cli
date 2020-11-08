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

Graphistry automatically uses the available resources (see monitoring section)

* Run one Graphistry install in a server with multiple CPUs and one or more GPUs
* Admins can restrict consumption via docker configurations, such as for noisey and greedy neighbor processes

### Cluster 
* Run multiple API servers by fronting a sticky-session load balancer

## OS and VM configuration

* Check `docker info` reports `Native Overlay Diff: true`
* Ensure virtualization layers are providing required resources

## Graphistry application-level configuration

* Check `LOG_LEVEL` and `GRAPHISTRY_LOG_LEVEL` (`data/config/custom.env`) is set to `INFO` or `ERROR`
* Add environment variables to `data/config/custom.env` based on available CPU/GPU cores and memory:
  * Default configuration aims to saturate a 1 GB (16 GB RAM) / 8 core (16 GB RAM) system
  * GPU live clustering: `STREAMGL_NUM_WORKERS`, defaults to `4`, recommend 1 per 4GB GPU and 4 GB CPU
  * GPU/CPU analytics:`FORGE_NUM_WORKERS`, defaults to `1`, recommend 1 per 4 GB GPU and 4 GB CPU
  * CPU network streaming and limited analytics: `STREAMGL_CPU_NUM_WORKERS`, defaults to `max`, recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS` (GPU sibling)
  * CPU upload handlers: `PM2_MAX_WORKERS`, defaults to `max`, recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS`
* If oversubscription is due to too many users running clustering, decrease `GRAPH_PLAY_TIMEOUTMS` from one minute, such as 30 seconds (30000 milliseconds)

## Let's chat

Performance can be tricky; we are happy to help via [your preferred communication channel](https://www.graphistry.com/support).
