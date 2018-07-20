# Analyzing Graphistry debug logs

If Graphistry starts and can load static resources, e.g., `www.yourgraphistry.com` 


## Setup

1. Enable debug logs

In folder `~/`, modify `(httpd|viz-app|pivot-app)-config.json` to turn on debug logs:

```
...
    "log": {
        "level": "debug"
    }
...
```

2. Restart Graphistry

3. Watch `nginx`, `central`, and `worker` logs:

* `tail -f deploy/nginx/*.log`
* `tail -f deploy/graphistry-json/central.log`
* `tail -f viz-worker*.log | grep -iv healthcheck`

4. Navigate browser to `http://www.yourgraphsitry.com/graph/graph.html?dataset=Facebook`

## Nginx

Nginx in debug mode should log the following sequence of `GET` and `POST` requests:

* `GET /graph/graph.html?dataset=Facebook`
* `GET /graph/graph.html?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>`
* `GET /worker/<WORKER_NUMBER>/socket.io/?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>`
* `GET /worker/<WORKER_NUMBER>/graph/img/logo_white_horiz.png`
* `5 x GET/POST /worker<WORKER_NUMBER>/socket.io/?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>...`
* `GET  /worker/<WORKER_NUMBER>/vbo?id=<SOME_ID>&buffer=curPoints`
50.0.128.91 - - [20/Jul/2018:06:58:01 +0000] "GET  /worker/10005/vbo?id=A6TtYcJu95TDahAeAAAA&buffer=pointSizes HTTP/1.1" 200 186 "http://ec2-35-172-213-119.compute-1.amazonaws.com/graph/graph.html?dataset=Facebook&workbook=4425d5abcd6c2167" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36" "-"
...
* `5 x GET  /worker/<WORKER_NUMBER>/vbo?id=<SOME_ID>&buffer=curPoints`



````
