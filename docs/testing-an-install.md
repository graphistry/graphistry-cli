# Manual inspection of all key running components

Takes about 5-10min. See `Quick Testing` below for an expedited variant.

To test your base Docker environment for GPU RAPIDS (but not docker-compose), [see the main docs](../README.md#test-your-environment-setup)

For logs throughout your session, you can run `docker-compose logs -f -t --tail=1` and `docker-compose logs -f -t --tail=1 SOME_SERVICE_NAME` to see the effects of your activities. Modify `custom.env` to increase `GRAPHISTRY_LOG_LEVEL` and `LOG_LEVEL` to `DEBUG` for increased logging, and `/etc/docker/daemon.json` to use log driver `json-file` for local logs.

NOTE: Below tests use the deprecated 1.0 REST upload API.

## 1. Start

* Put the container in `/var/home/my_user/releases/my_release_1`: Ensures relative paths work, and good persistence hygiene across upgrades
* Go time!
```
docker load -i containters.tar
docker-compose up
```

* Check health status via `docker ps`. Check resource consumption via `docker stats`, `nvidia-smi`, and `htop`
* Check `data/config/custom.env` has system-local keys (ex: `STREAMGL_SECRET_KEY`) with fallback to `.env`


## 2. Basic web servers and networking

* Check `caddy` and `nginx`: Go to https://graphistry/healthz via your browser or curl: should return status code`200`
* Check `nexus` for auth, admin, docs, static resources, and API gateway: 
  * Go to https://graphistry
  * Should be a login page or your user dashboard

## 3. GPU visual analysis of preloaded dataset 

* Go to your https://graphistry/graph/graph.html?dataset=Facebook
  * Can also get by point-and-clicking if URL is uncertain: http://graphistry -> `Learn More` -> (the page)
* Expect to see something similar to https://hub.graphistry.com/graph/graph.html?dataset=Facebook
  * If points do not load, or appear and freeze, likely issues with GPU init (driver) or websocket (firewall)
  * Can also be because preloaded datasets are unavailable: not provided, or externally mounted data sources
    * In this case, use ETL test, and ensure clustering runs for a few seconds (vs. just initial pageload)
* Check `docker-compose logs -f -t --tail=1` and `docker ps` in case config or GPU driver issues

## 4a. Test 1.0 API uploads, Jupyter, and the PyGraphistry client API

Do via notebook if possible, else `curl`

* Get a 1.0 API key by logging into your user's dashboard, or generating a new one using host access:

```
docker-compose exec central curl -s http://localhost:10000/api/internal/provision?text=MYUSERNAME
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
docker-compose exec central curl -s http://localhost:10000/api/internal/provision?text=MYUSERNAME
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
docker-compose stop
docker-compose up
```


#### 4c.i Persistence

* Pivot should persist to `./data` already by default, no need to do anything
* Run a pivot investigation and save: should see `data/{investigation,pivot,workbook_cache,data_cache}/*.json`

#### 4c.ii Connector - Splunk

* Edit `data/custom/custom.env` for `SPLUNK_HOST`, `SPLUNK_PORT`, `SPLUNK_USER`, `SPLUNK_KEY`
* Restart the `/pivot` service: `docker-compose restart pivot`
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

#### 4c.iv Connector - Neo4j

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
  
## 5. Test TLS Certificates

Cloud:
* Ensure domain<>IP assignment
  * In EC2/Azure: Allocate an Elastic/Static IP to your instance (may be optional)
  * In Route53/DNS: Assign a domain to your IP, ex: `mytest.graphistry.com`
* Modify `data/config/Caddyfile` to use your domain name
  * Unlikely: If needed, run `DOMAIN=my.site.com ./scripts/letsencrypt.sh` and `./gen_dhparam.sh`
  * Restart `docker-compose restart caddy`, check pages load
* Try a notebook upload with `graphistry.register(...., protocol='https')`

## 6. Quick Testing and Test GPU

* `docker ps` reports no "unhealthy", "restarting", or prolonged "starting" services
  * check `docker-compose logs`, `docker-compose logs <service>`, `docker-compose logs -f -t --tail=100 service`
  * unhealthy `streamgl`, `gpu`, `viz`, `forge-etl`: likely GPU driver issue
    * GPU is not the default runtime in `/etc/docker/deamon.json` (`docker info | grep Default`)
    * `OpenlCL` Initialization error: GPU drivers insufficently setup
    * `NVRTC error: NVRTC_ERROR_INVALID_OPTION`: Check GPU/drivers for RAPIDS compatiblility
    * `forge-etl`: restart the service (bad start) or RAPIDS-incompatible GPU/drivers
  * unhealthy `pivot`: likely config file issue
  * unhealthy `nginx`, `nexus`, `caddy`: 
    * likely config file issue, unable to start due to other upstream services, or public ports are already taken

* If a GPU service is unhealthy, the typical cause is an unhealthy Nvidia host or Nvidia container environment setup. Pinpoint the misconfiguration through the following progression, or run as part of `etc/scripts/test-gpu.sh` (Graphistry 2.33+). For on-prem users, your `container.tar` load will import Nvidia's official `nvidia/cuda` container used by Graphistry your version, which can aid pinpointing ecosystem issues outside of Graphistry (v2.33.20+).
  * `docker run hello-world` reports a message <-- tests CPU Docker installation
  * `nvidia-smi` reports available GPUs  <-- tests host has a GPU configured with expected GPU driver version number
  * `docker run --gpus nvidia/cuda nvidia-smi` reports available GPUs <-- tests nvidia-docker installation
  * `docker run --runtime=nvidia nvidia/cuda nvidia-smi` reports available GPUs <-- tests nvidia-docker installation
  * `docker run --rm nvidia/cuda  nvidia-smi` reports available GPUs <-- tests Docker GPU defaults (used by docker-compose via /etc/docker/daemon.json)
  * "docker run --rm graphistry/graphistry-blazing:`cat VERSION`-dev nvidia-smi" reports available GPUs (public base image) <- tests Graphistry container CUDA versions are compatible with host versions
  * "docker run --rm graphistry/etl-server-python:`cat VERSION`-dev nvidia-smi" reports available GPUs (application image)
  * Repeat the docker tests, but with `cudf` execution. Ex:
    `docker run --rm -it --entrypoint=/bin/bash graphistry/etl-server-python:`cat VERSION` -c "source activate rapids && python3 -c \"import cudf; print(cudf.DataFrame({'x': [0,1,2]})['x'].sum())\""` <-- tests Nvidia RAPIDS  (VERSION is your Graphistry version)
  * `docker run graphistry/cljs:1.1 npm test` reports success  <-- tests driver versioning, may be a faulty test however
  * If running in a hypervisor, ensure `RMM_ALLOCATOR=default` in `data/config/custom.env`, and check the startup logs of `docker-compose logs -f -t --tail=1000 forge-etl-python` that `cudf` / `cupy` / `BlazingSQL` are respecting that setting (`LOG_LEVEL=INFO`)
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
    * When clicking the ``Status`` button for each connector, it reports green. Check error reported in UI or docker logs (`docker compose logs -f -t pivot`): likely configuration issues such as password, URL domain vs fqdn, or firewall.
  *  Opening and running an investigation in ``site.com/pivot`` uploads and shows a graph
