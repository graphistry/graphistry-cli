# Analyzing Graphistry visual session debug logs

Life happens. This document describes how to inspect the backend logs for loading a visualization and how that may narrow down failures to specific services. For example, if a firewall is blocking file access, the data loader may fail. 

It covers the core visualization service. It does not cover the graph upload service nor the investigation template environment.

## Prerequisites

* Graphistry starts (seeing `docker ps` section of your install guide) with no restart loops
* Graphistry documentation loads: going to `mygraphistry.com` shows a page similar to `https://hub.graphistry.com/`.
* Logged into system terminal for a Graphistry server

## Setup

1. Ensure log location

Modify `/etc/docker/daemon.json` to send logs to the intended location:
* Local: JSON recommended
* Remote: see Graphistry AWS/Azure marketplace images for sample Splunk docker driver

Restart docker and Graphistry if modified.

2. Enable debug logs

In folder `~/data/config`, modify `custom.env` to turn on debug logs:

```
LOG_LEVEL=DEBUG
GRAPHISTRY_LOG_LEVEL=DEBUG
```

For more fidelity, use `TRACE`. Make sure to set back to `INFO` or higher after: This fixes performance and prevents leaking secrets.

To debug a specific service, you can selectively modify its log level through an environment variable in `data/config/custom.env` and restart: `./graphistry up -d --force-recreate`.

3. Restart Graphistry (`docker restart <containerid>`)

4. Ensure all workers reported in and are ready:

* GPU: `docker ps` => healthy for `streamgl-gpu`, `forge-etl-python`
* CPU: `docker ps` => healthy for `forge-etl`, `streamgl-viz`

5. Watch logs:

* `docker logs -f -t --tail=100`: watch all running services, including starting with the past 100 lines each
* `docker logs -f -t streamgl-viz streamgl-gpu forge-etl-python`: focus on a few viz services

Clear screen before starting the test session.

6. Start test session: 

Navigate browser to `https://www.yourgraphistry.com/graph/graph.html?dataset=Facebook`


## Client logs

The browser developer panel, especially around console logs and history of network requests, may provide hints at the first failing request and corresponding error


## Nginx logs

Nginx in debug mode should log the following sequence of `GET` and `POST` requests. An error or early stop hints at which service is failing. The pipeline is roughly: create a session's workbook, redirect the user to it, starts a GPU service session, loads the static UI, connect a browser's socket to the GPU session, and then starts streaming visual data to the browser.

1. `GET /graph/graph.html?dataset=Facebook`
2. `GET /graph/graph.html?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>`
3. `GET /worker/<WORKER_NUMBER>/socket.io/?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>`
4. `GET /worker/<WORKER_NUMBER>/graph/img/logo_white_horiz.png`
5. `5 x GET/POST /worker<WORKER_NUMBER>/socket.io/?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>...`
6. `GET  /worker/<WORKER_NUMBER>/vbo?...`


