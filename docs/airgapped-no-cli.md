# Airgapped Installation of Graphistry Without Python CLI

Graphistry can be installed and administered directly without the CLI. While this administration mode is not recommended due to losing the benefits of a managed administration process, it does avoid restrictions such as system installation of Python.

Contents:
* Quickstart
* Detailed

  0. Prerequisites
  
  1. Untar and load Graphistry
  
  2. Configure for local use
  
  3. Launch
  
* Administer
* Test

## Quickstart

```
### docker, cuda, nvidia-docker:
### 10,20,30,40.sh from graphistry-cli/graphistry/bootstrap/rhel (can skip Python)

~ $ tar -xvvf graphistry.tar.gz
~ $ docker load -i containers.tar

### set pivot-config.json::graphistry.host, defaults ok for rest of (httpd,pivot,viz-app)-config.json
~ $ vi ~/pivot-config.json 

~ $ cd deploy && SHIPYARD=1 ./launch.sh
```



## Detailed

### 0. Prerequisites


* Files
  * Graphistry: *.tar.gz file
  * Config templates: `(httpd,pivot,viz-app)-config.json` (https://github.com/graphistry/graphistry-cli/blob/master/docs/config-files)
* Server:
  * OS: RHEL 7.5 / Ubuntu 16.04 LTS /CentOS
  * CPU: 8GB+ CPU RAM; recommended 4+ cores with 16+ GB RAM
  * GPU: CUDA-capable Nvidia GPU (Tesla, Pasal, Volta series) with 4GB+ RAM; recommended 12+ GB GPU RAM
* Server configured for Nvidia-Docker:
  * Docker (RHEL): https://github.com/graphistry/graphistry-cli/blob/master/graphistry/bootstrap/rhel/20-docker.sh
  * CUDA 9.1 (RHEL): https://github.com/graphistry/graphistry-cli/blob/master/graphistry/bootstrap/rhel/30-CUDA.sh
  * Nivida-Docker-1 (RHEL): https://github.com/graphistry/graphistry-cli/blob/master/graphistry/bootstrap/rhel/40-nvidia-docker.sh
  * _Alternatives_: Ubuntu, RHEL, CentOS -- https://github.com/graphistry/graphistry-cli/tree/master/graphistry/bootstrap
* Browser: Chrome/Firefox with WebGL enabled


### 1. Untar and load Graphistry

```
tar -xvvf graphistry.tar.gz
docker load -i containers.tar
```

You should now have `~/deploy/launch.sh` and `~/containers.tar`.

### 2. Configure for local use

* Copy `(httpd,pivot,viz-app)-config.json` into `~/`  
  * Reference: https://github.com/graphistry/graphistry-cli/blob/master/docs/config-files
* Fill in `pivot-config.json` entry `{"graphistry": {"host": "http://YOUR.GRAPHISTRY.COM"}}`, taking care to include the protocol

### 3. Launch

```
cd ~/deploy
SHIPYARD=yes ./launch.sh
```

## Administer

### Stop

If you only have Graphistry containers running:

```
docker stop $(docker ps -a -q)
```

If yopu have non-Graphistry containers also running, use `docker stop` for each of `nginx-central-vizservers, graphistry/pivot-app, graphistry/viz-app, mongo, s3cmd-postgres, postgres:9-alpine`.


### Restart

```
cd ~/deploy
SHIPYARD=yes ./launch.sh
```

It is always safe to remove all containers and load them again, e.g., `docker system prune -a`.

### Reinstall or Upgrade

* Stop the system, and potentially, `docker system prune -a`
* Run `docker load -i containers.tar` on the new system
* Using the **new** `deploy` (e.g., `~/deploy $ SHIPYARD=1 ./launch.sh`), start as usual

### Inspect

* See below test instructions around `docker ps` and healthchecks
* Logs: 
  * `docker logs <container>`
  * `tail -f ~/deploy/worker/*.log`
  * `tail -f ~/deploy/pivot-app/*.log`

## Test

* Base environment
  * `docker ps` shows 0 or more containers running
  * `nvidia-smi` lists a GPU
  * `nvidia-docker run --rm nvidia/cuda nvidia-smi` shows 0 or more containers running 
  * `nvidia-docker run --rm graphistry/viz-app nvidia-smi` shows 0 or more containers running 
* Services are running: ``docker ps`` reveals no restart loops on:
  * ``graphistry/nginx-central-vizservers``
  * ``graphistry/pivot-app``
  * ``graphistry/viz-app``
  * ``mongo``
  * ``graphistry/s3cmd-postgres``
  * ``postgres:9-alpine``
* Services pass initial healthchecks:
  * ``site.com/central/healthcheck``
  * ``site.com/pivot/healthcheck``
  * ``site.com/worker/10000/healthcheck``
* Pages load: Visualization
  * ``site.com`` shows Graphistry homepage
  * ``site.com/graph/graph.html?dataset=Facebook`` clusters and renders a graph
* Pages load: Investigation
  * ``site.com/pivot`` loads a list of investigations (`admin`/`admin`)
  * ``site.com/pivot/connectors`` loads a list of connectors
  * ^^^ When clicking the ``Status`` button for each connector, it reports green
  *  Opening and running an investigation in ``site.com/pivot`` uploads and shows a graph
* Data uploads
  * Can generate an API key with the CLI: ``graphistry`` --> ``keygen``
  * Can use the key to upload a visualization: https://graphistry.github.io/docs/legacy/api/0.9.2/api.html#curlexample
  * Can then open that visualization in a browser


