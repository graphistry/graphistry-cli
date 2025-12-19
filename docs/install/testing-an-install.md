# Testing an Install

Takes about 5-10min. See `Quick Testing` below for an expedited variant.

Most of the testing and inspection is standard for Docker-based web apps: `docker` commands, health check URLs, and optional manual smoke tests. GPU testing and debugging involves additional steps.

* To test your base Docker environment for GPU RAPIDS, see the in-depth GPU testing section below.

* For logs throughout your session, you can run `./graphistry logs -f -t --tail=1` and `./graphistry logs -f -t --tail=1 SOME_SERVICE_NAME` to see the effects of your activities. Modify `custom.env` to increase `GRAPHISTRY_LOG_LEVEL` and `LOG_LEVEL` to `DEBUG` for increased logging, and `/etc/docker/daemon.json` to use log driver `json-file` for local logs.

NOTE: Below tests use the deprecated 1.0 REST upload API.

## 1. Start

* Put the container in `/var/home/my_user/releases/my_release_1`: Ensures relative paths work, and good persistence hygiene across upgrades
* Go time!
```
docker load -i containers.tar.gz
docker-compose up
```

* Check health status via `docker ps` or via the [health check REST APIs](https://hub.graphistry.com/docs/api/2/rest/health/#healthchecks). Check resource consumption via `docker stats`, `nvidia-smi`, and `htop`. Note that the set of services evolves across releases:

```
CONTAINER ID   NAME                              CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O         PIDS
34f3cf3f9833   compose_nginx_1                   0.00%     23.91MiB / 31.27GiB   0.07%     10.7MB / 11.4MB   1.3MB / 49.2kB    27
3e876f4acf19   compose_forge-etl-python_1        0.08%     1.376GiB / 2.93GiB    46.96%    137kB / 294kB     186MB / 16.4kB    27
ea097f97aac9   compose_pivot_1                   0.00%     87.87MiB / 31.27GiB   0.27%     27.1kB / 1.91kB   28.5MB / 8.19kB   20
2a2307451f30   compose_dask-cuda-worker_1        1.95%     1.147GiB / 8.789GiB   13.05%    839kB / 1.79MB    70.4MB / 8.19kB   22
6d088ab08cfe   compose_streamgl-viz_1            0.23%     202.6MiB / 31.27GiB   0.63%     52.8kB / 11.4kB   287kB / 8.19kB    23
aaf1d61a5de1   compose_notebook_1                0.00%     213.3MiB / 31.27GiB   0.67%     244kB / 7.24MB    58.5MB / 36.9kB   7
06d8ee55767d   compose_streamgl-gpu_1            0.97%     717MiB / 31.27GiB     2.24%     26kB / 1.17kB     41.5MB / 8.19kB   84
b1c4f9b4de53   compose_nexus_1                   0.03%     140.4MiB / 31.27GiB   0.44%     1.02MB / 1.46MB   106MB / 8.19kB    5
a386ff2f93f9   compose_streamgl-sessions_1       0.03%     149.4MiB / 31.27GiB   0.47%     29.3kB / 1.2kB    29MB / 8.19kB     12
2a46c4645224   compose_dask-scheduler_1          1.04%     142.2MiB / 31.27GiB   0.44%     2.09MB / 913kB    55.9MB / 8.19kB   6
ed3a5d6e25ad   compose_forge-etl_1               0.24%     189.9MiB / 31.27GiB   0.59%     28.1kB / 1.17kB   15.4MB / 8.19kB   23
e9bd7d2fa43c   compose_caddy_1                   0.00%     19.74MiB / 31.27GiB   0.06%     11.4MB / 11.4MB   11.9MB / 4.1kB    26
351b27c75b8c   compose_streamgl-vgraph-etl_1     0.01%     128.3MiB / 31.27GiB   0.40%     30.6kB / 3.93kB   16MB / 8.19kB     12
2c596681e5c9   compose_graph-app-kit-public_1    0.00%     133MiB / 31.27GiB     0.42%     56.3kB / 2.81MB   62.9MB / 8.19kB   6
a31f9f54a506   compose_graph-app-kit-private_1   0.00%     97.94MiB / 31.27GiB   0.31%     27.2kB / 644B     6.5MB / 8.19kB    6
aeed3469d559   compose_autoheal_1                0.00%     4.316MiB / 31.27GiB   0.01%     26.9kB / 0B       4.97MB / 0B       2
2ae36f5256e8   compose_postgres_1                0.00%     55.05MiB / 31.27GiB   0.17%     1.16MB / 912kB    13.8MB / 75.6MB   7
f0bc21b5bda2   compose_redis_1                   0.05%     6.781MiB / 31.27GiB   0.02%     29kB / 10.1kB     4.95MB / 0B       5
```

| Type | Containers |
| ---: | :--- |
| Proxies | `caddy`, `nginx` |
| Infra | `autoheal` |
| Web (DB/CMS/accounts) | `nexus` `postgres`, `redis` |
| GPU services | `streamgl-gpu` <br/> image `graphistry/etl-server-python`: `forge-etl-python`, `dask-scheduler`, `dask-cuda-worker` |
| JS viz services | `streamgl-viz` (heavy), `streamgl-sessions`, `streamgl-vgraph-etl` |
| Investigation automation | `pivot` (heavy) |
| Jupyter notebooks | `notebook` (heavy) |
| Dashboards | `graph-app-kit-public`, `graph-app-kit-private` |
   
* It is safe to reset any individual container **except** `postgres`, which is stateful: `./graphistry up -d --force-recreate --no-deps <some_stateless_services>`

* For any unhealthy container, such as stuck in a restart loop, check `./graphistry logs -f -t --tail=1000 that_service`. To further diagnose, potentially increase the system log level (edit `data/config/custom.env` to have `LOG_LEVEL=DEBUG`, `GRAPHISTRY_LOG_LEVEL=DEBUG`) and recreate + restart the unhealthy container

* Check `data/config/custom.env` has system-local keys (ex: `STREAMGL_SECRET_KEY`) with fallback to `.env`


## 2. Basic web servers and networking

* Check `caddy` and `nginx`: Check https://localhost/caddy/health/ (caddy) and http://localhost/healthz (nginx) via your browser or `curl -v http://...`: should return status code `200`
* Check `nexus` for auth, admin, docs, static resources, and API gateway: 
  * Go to https://localhost
  * Should be a login page or your user dashboard

## 3. GPU visual analysis of preloaded dataset 

* Go to your https://graphistry/graph/graph.html?dataset=Facebook
  * Can also get by point-and-clicking if URL is uncertain: http://graphistry -> `Learn More` -> (the page)
* Expect to see something similar to https://hub.graphistry.com/graph/graph.html?dataset=Facebook
  * The first system load (per GPU worker) will be slow due to GPU JIT warmup; wait 30s-1min and refresh if the page loads but no graph is shown
  * If points still do not load, or appear and freeze, likely issues with GPU init (driver) or websocket (firewall)
  * Can also be because preloaded datasets are unavailable: not provided, or externally mounted data sources
    * In this case, use ETL test, and ensure clustering runs for a few seconds (vs. just initial pageload)
* Check `./graphistry logs -f -t --tail=1` and `docker ps` in case config or GPU driver issues, especially for GPU services listed above
* Upon failures, see below section on GPU testing

## 4a. Test 1.0 API uploads, Jupyter, and the PyGraphistry client API

Do via notebook if possible, else `curl`

* Get a 1.0 API key by logging into your user's dashboard, or generating a new one using host access:

```
./graphistry exec central curl -s http://localhost:10000/api/internal/provision?text=MYUSERNAME
```

* Install PyGraphistry and check recent version number (Latest: https://pypi.org/project/graphistry/), or use the provided `/notebook` install:

```
!pip install graphistry -q
import graphistry
graphistry.__version__
```

* Try your 1.0 API key, will complain if invalid, otherwise silent

```
graphistry.register(protocol='https', server='my.server.com', key='my_key')
```

* Try upload and viz, may need to open result in new tab if HTTPS notebook for HTTP graphistry. Expect to see a triangle:

```
import pandas as pd
df = pd.DataFrame({'s': [0,1,2], 'd': [1,2,0]})
graphistry.bind(source='s', destination='d').plot(df)
```

## 4b. Test `/etl` by commandline

If you cannot do **3a**, test from the host via `curl` or `wget`:

* Make `samplegraph.json` (1.0 API format):

```
{
    "name": "myUniqueGraphName",
    "type": "edgelist",
    "bindings": {
        "sourceField": "src",
        "destinationField": "dst",
        "idField": "node"
    },
    "graph": [
      {"src": "myNode1", "dst": "myNode2",
       "myEdgeField1": "I'm an edge!", "myCount": 7},
      {"src": "myNode2", "dst": "myNode3",
        "myEdgeField1": "I'm also an edge!", "myCount": 200}
    ],
    "labels": [
      {"node": "myNode1",
       "myNodeField1": "I'm a node!",
       "pointColor": 5},
      {"node": "myNode2",
       "myNodeField1": "I'm a node too!",
       "pointColor": 4},
      {"node": "myNode3",
       "myNodeField1": "I'm a node three!",
       "pointColor": 4}
    ]
}
```

* Get a 1.0 API key

Login and get the API key from your dashboard homepage, or run the following:

```
./graphistry exec central curl -s http://localhost:10000/api/internal/provision?text=MYUSERNAME
```

* Upload your 1.0 API data using the key

```
curl -H "Content-type: application/json" -X POST -d @samplegraph.json https://graphistry/etl?key=YOUR_API_KEY_HERE
```

* From response, go to corresponding https://graphistry/graph/graph.html?dataset=... 
  * check the viz loads 
  * check the GPU iteratively clusters


## 5. Test pivot

### 5a. Basic
* Test it loads at https://graphistry/pivot
* Connector page only shows WHOIS and HTTP pivots (https://graphistry/pivot/connectors), and clicking them returns green

### 5b. Investigation page

* Starts empty at https://graphistry/pivot/home
* Pressing `+` creates a new untitled investigations
* Can create and run a manual pivot in it, with settings:
```
Pivot: Enter data
Events: [ { "x": 1, "y": "b"} ]
Nodes: x y
  * Expect to see a graph with 1 event node, and 2 connected entity nodes `1` and `b`
```

### 5c. Configurations

* Edit `data/config/custom.env` and `docker-compose.yml` as per below
  * Set each config in one go so you can test more quickly, vs start/stop. 
* Run
```
./graphistry stop
./graphistry up
```


#### 5c.i Persistence

* Pivot should persist to `./data` already by default, no need to do anything
* Run a pivot investigation and save: should see `data/{investigation,pivot,workbook_cache,data_cache}/*.json`

#### 5c.ii Connector - Splunk

* Edit `data/custom/custom.env` for `SPLUNK_HOST`, `SPLUNK_PORT`, `SPLUNK_USER`, `SPLUNK_KEY`
* Restart the `/pivot` service: `./graphistry restart pivot`
* In `/pivot/connectors`, the `Live Connectors` should list `Splunk`, and clicking `Status` will test logging in
* In `Investigations and Templates`, create a new investigation:
  * Create and run one pivot:
```
Pivot: Search: Splunk
Query: *
Max Results: 2
Entities: *
```
  * Expect to see two orange nodes on the first line, connected to many nodes in the second

#### 5c.iv Connector - Neo4j

* Edit `.env` for `NEO4J_BOLT` (`bolt://...:...`), `NEO4J_USER`, `NEO4J_PASSWORD`
* Test status button in http://graphistry/pivot/connectors
* Make a new investigation
  * Pivot 1
```
Pivot: Search: Neo4j
Query: MATCH (a)-[e*2]->(b) RETURN a,e,b
Max Results: 10
Entities: *
```  
  * Pivot 2
```
Pivot: Expand: Neo4j
Depends on Pivot 1
Max Results: 20
Steps out: 1..1
```  
  * Run all: Gets values for both
  
## 6. Test TLS Certificates

Cloud:
* Ensure domain<>IP assignment
  * In EC2/Azure: Allocate an Elastic/Static IP to your instance (may be optional)
  * In Route53/DNS: Assign a domain to your IP, ex: `mytest.graphistry.com`
* Modify `data/config/Caddyfile` to use your domain name
  * Unlikely: If needed, run `DOMAIN=my.site.com ./scripts/letsencrypt.sh` and `./gen_dhparam.sh`
  * Restart `./graphistry restart caddy`, check pages load
* Try a notebook upload with `graphistry.register(...., protocol='https')`

## 7. Quick Testing and Test GPU

Most of the below tests can be automatically run by `cd etc/scripts && ./test-gpu.sh`:
  * Checks `nvidia-smi` works in your OS
  * Checks `nvidia-smi` works in Docker, including runtime defaults used by `./graphistry`
  * Checks Nvidia RAPIDS can successfully create CUDA contexts and run a simple on-GPU compute and I/O task of `1 + 1 == 2`

`docker ps` reports no "unhealthy", "restarting", or prolonged "starting" services:
  * check `./graphistry logs`, `./graphistry logs <service>`, `./graphistry logs -f -t --tail=100 <service>`
  * unhealthy `streamgl-gpu`, `forge-etl-python` on start: likely GPU driver issue
    * GPU is not the default runtime in `/etc/docker/deamon.json` (`docker info | grep Default`)
    * `OpenlCL` Initialization error: GPU drivers insufficently setup
    * `NVRTC error: NVRTC_ERROR_INVALID_OPTION`: Check GPU/drivers for RAPIDS compatiblility
    * `forge-etl`: restart the service (bad start) or RAPIDS-incompatible GPU/drivers
  * unhealthy `pivot`: likely config file issue
  * unhealthy `nginx`, `nexus`, `caddy`: 
    * likely config file issue, unable to start due to other upstream services, or public ports are already taken

* If a GPU service is unhealthy, the typical cause is an unhealthy Nvidia host or Nvidia container environment setup. Pinpoint the misconfiguration through the following progression, or run as part of `etc/scripts/test-gpu.sh` (Graphistry 2.33+). For on-prem users, your `container.tar` load will import Nvidia's official `docker.io/rapidsai/base:24.04-cuda11.8-py3.10` container used by Graphistry your version, which can aid pinpointing ecosystem issues outside of Graphistry (v2.33.20+).
  * `docker run hello-world` reports a message <-- tests CPU Docker installation
  * `nvidia-smi` reports available GPUs  <-- tests host has a GPU configured with expected GPU driver version number
  * `docker run --gpus=all docker.io/rapidsai/base:24.04-cuda11.8-py3.10 nvidia-smi` reports available GPUs <-- tests nvidia-docker installation
  * `docker run --runtime=nvidia docker.io/rapidsai/base:24.04-cuda11.8-py3.10 nvidia-smi` reports available GPUs <-- tests nvidia-docker installation
  * `docker run --rm docker.io/rapidsai/base:24.04-cuda11.8-py3.10  nvidia-smi` reports available GPUs <-- tests Docker GPU defaults (used by docker-compose via `/etc/docker/daemon.json`)
  * ``docker run --rm graphistry/graphistry-forge-base:`cat VERSION`-11.8 nvidia-smi``
Reports available GPUs (public base image) <- tests Graphistry container CUDA versions are compatible with host versions
  * ``docker run --rm graphistry/etl-server-python:`cat VERSION`-11.8 nvidia-smi``
    Reports available GPUs (application image)
  * Repeat the docker tests, but with `cudf` execution. Ex:
    ``docker run --rm -it --entrypoint=/bin/bash graphistry/etl-server-python:`cat VERSION`-11.8 -c "source activate base && python3 -c \"import cudf; print(cudf.DataFrame({'x': [0,1,2]})['x'].sum())\""``
Tests Nvidia RAPIDS  (VERSION is your Graphistry version)
  * `docker run graphistry/cljs:1.1 npm test` reports success  <-- tests driver versioning, may be a faulty test however
  * If running in a hypervisor, ensure `RMM_ALLOCATOR=default` in `data/config/custom.env`, and check the startup logs of `./graphistry logs -f -t --tail=1000 forge-etl-python` that `cudf` / `cupy` are respecting that setting (`LOG_LEVEL=INFO`)
* Health checks
  * CLI: Check `docker ps` for per-service status, may take 1-2min for services to connect and warm up
    * Per-service checks run every ~30s after a ~1min initialization delay, with several retries before capped restart
    * Configure via `docker-compose.yml`
  * URLs: See [official list](https://hub.graphistry.com/docs/api/2/rest/health/)
* Pages load
  * ``site.com`` shows Graphistry homepage and is stylized <-- Static assets are functioning
  * ``site.com/graph/graph.html?dataset=Facebook`` clusters and renders a graph
    * If the page loads but the graph is empty, see above instructions for testing Nvidia environment
    * Check browser console logs for WebGL errors
    * Check browser and network logs for Websocket errors, which may require a change in `Caddy` reverse proxying
* Notebooks
  * Running the analyst notebook example generates running visualizations (see logged-in homepage)
  * For further information about the Notebook client, see the OSS project [PyGraphistry](http://github.com/graphistry/pygraphistry) ( [PyPI](https://pypi.org/project/graphistry/) ).
* Investigations
  * ``site.com/pivot`` loads
  * ``site.com/pivot/connectors`` loads a list of connectors
    * When clicking the ``Status`` button for each connector, it reports green. Check error reported in UI or docker logs (`./graphistry logs -f -t pivot`): likely configuration issues such as password, URL domain vs fqdn, or firewall.
  *  Opening and running an investigation in ``site.com/pivot`` uploads and shows a graph


## 8. Dashboard

* When logged out, ensure `site.com/public/dash/` loads (note trailing slash), corresponding to `graph-app-kit-public`
* When logged in as admin/staff, ensure `site.com/private/dash/` loads (note trailing slash), corresponding to `graph-app-kit-private`
