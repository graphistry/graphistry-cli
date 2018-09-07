Graphistry System Debugging FAQ

## List of Issues

1. Started before initialization completed
2. GPU driver misconfiguration
3. Wrong or mismatched containers installed


## 1. Issue: Started before initialization completed

### Primary symptom
Visualization page never returns or Nginx "504 Gateway Time-out" due to services still initializing." Potentially  also "502".

### Correlated symptoms:
* GPU tests pass  
* Often with first-ever container launch
* Likely within 60s of launch
* Can happen even after static homepage loads
* In `docker-compose up` logs (or `docker logs ubuntu_central_1`):
  * "Error: Server at maximum capacity...
  * "Error: Too many users...
  * "Error while assigning...


### Solution:
* Try stopping and starting the containers
* Wait for 1-2min after start and try again
  * Viz container should report a bunch of `INFO success: viz-worker-10006 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)`
  * Mongo container should report a bunch of `I ACCESS   [conn66] Successfully authenticated as principal graphistry on cluster`


## 2. Issue: GPU driver misconfiguration

* Visualization loads and positions appear, but never start clustering.
* Visualization page never returns or Nginx "504 Gateway Time-out" due to services failing to initialize GPU context. Potentially also "502".

### Correlated symptoms:
* `node` processes in `ubuntu_viz_1` container fail to run for more than 30s (check durations through `docker exec -it ubuntu_viz_1 ps "-aux"`)
* Upon manually starting a worker in `ubuntu_viz_1`, error message having to do with GPUs (Nvidia, OpenCL, drivers, context, ...)
  * `docker exec -it ubuntu_viz_1 bash -c "VIZ_LISTEN_PORT=7000 node /opt/graphistry/apps/core/viz/index.js"`
* GPU tests fail
  * host
    * `nvidia-smi`
    * See https://www.npmjs.com/package/@graphistry/cljs    
      * _note_: Requires CL installed in host, which Graphistry normally does not require
  * container
    * ./graphistry-cli/graphistry/bootstrap/ubuntu-cuda9.2/test-20-docker.sh 
    * ./graphistry-cli/graphistry/bootstrap/ubuntu-cuda9.2/test-30-CUDA.sh 
    * ./graphistry-cli/graphistry/bootstrap/ubuntu-cuda9.2/test-40-nvidia-docker.sh
    * nvidia-docker run --rm nvidia/cuda nvidia-smi
    * nvidia-docker exec -it ubuntu_viz_1 nvidia-smi
    * See https://www.npmjs.com/package/@graphistry/cljs
    * Check running the following `node` script from within `ubuntu_viz_1` container:

`node __test-nvidia.js__` 
(Place in `ubuntu_viz_1` container from folder `/opt/graphistry/apps/lib/cljs/test/cl`):
```
const cl = require('node-opencl');
const { argv } = require('../util');
const { CLPlatform, CLDeviceTypes } = require('../../');
CLPlatform.devices('gpu')[0].isNvidiaDevice === true
```


### Solution:
* Based on where the issue is according to the above tests, fix that installation layer

## 3. Issue: Wrong or mismatched containers installed

Especially when upgrading, only some images may have updated. You can delete all of them and start from scratch.

### Correlated symptoms
* `docker images` or `docker ps` shows surprising versions

### Solution

Delete graphistry images and reinstall
* Identify installed images: `docker images | grep graphistry` and `docker images | grep nvidia`
* Remove: `docker rmi -f graphistry/nginx-proxy graphistry/graphistry-central ...`
* Reload: `docker load -i containers.tar`




