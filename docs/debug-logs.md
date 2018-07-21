# Analyzing Graphistry visual session debug logs

Sometimes visualizations fail to load. This document describes how to inspect the backend logs for loading a visualization and how that may narrow down failures to specific services. For example, if a firewall is blocking file access, the data loader may fail. 

It covers the core visualization service. It does not cover the graph upload service nor the investigation template environment.

## Prerequisites

* Graphistry starts (seeing `docker ps` section of your install guide) with no restart loops
* Graphistry documentation loads: going to `mygraphistry.com` shows a page similar to `http://labs.graphistry.com/`.
* Logged into system terminal for a Graphistry server

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

2. Restart Graphistry (`docker restart <containerid>`)

3. Ensure all workers reported in and are ready:

```docker exec monolith-network-mongo mongo localhost/cluster --eval "printjson(db.node_monitor.find({}).toArray())"```

Should report 32 workers that look like:
```
{
        "_id" : ObjectId("5b5022ab689859b490c6bae3"),
        "ip" : "localhost",
        "pid" : 25,
        "port" : 10001,
        "active" : false,
        "updated" : ISODate("2018-07-20T00:13:38.957Z")
}
```

4. Watch `nginx`, `central`, and `worker` logs:

* `tail -f deploy/nginx/*.log`
* `tail -f deploy/graphistry-json/central.log`
* `tail -f viz-worker*.log | grep -iv healthcheck`

Clear screen before starting the test session.


5. Start test session: Navigate browser to `http://www.yourgraphistry.com/graph/graph.html?dataset=Facebook`


## Nginx logs

Nginx in debug mode should log the following sequence of `GET` and `POST` requests. An error or early stop hints at which service is failing. The pipeline is roughly: create a session's workbook, redirect the user to it, starts a GPU service session, loads the static UI, connect a browser's socket to the GPU session, and then starts streaming visual data to the browser.

1. `GET /graph/graph.html?dataset=Facebook`
2. `GET /graph/graph.html?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>`
3. `GET /worker/<WORKER_NUMBER>/socket.io/?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>`
4. `GET /worker/<WORKER_NUMBER>/graph/img/logo_white_horiz.png`
5. `5 x GET/POST /worker<WORKER_NUMBER>/socket.io/?dataset=Facebook&workbook=<SOME_FRAGMENT_STRING>...`
6. `GET  /worker/<WORKER_NUMBER>/vbo?...`


## Central logs

Central in debug mode should log the successful process of identifying a free worker and redirecting to it. It hints at problems around steps 1 & 2 of the Nginx sequence. 

To increase legibility, you can also pipe the JSON logs through a pretty printer like [Bunyan](https://github.com/trentm/node-bunyan).

```
{"name":"graphistry","metadata":{"userInfo":{}},"hostname":"cbf3628eef58","pid":32,"module":"central","fileName":"central/lib/server.js","level":20,"req":{"method":"GET","url":"/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a","headers":{"host":"ec2-35-172-213-119.compute-1.amazonaws.com","x-real-ip":"50.0.128.91","x-forwarded-for":"50.0.128.91","x-forwarded-proto":"http","connection":"close","x-graphistry-prefix":"/worker/","upgrade-insecure-requests":"1","user-agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36","accept":"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8","accept-encoding":"gzip, deflate","accept-language":"en-US,en;q=0.9","cookie":"io=jQsh2lrAOdi17hGJAAAA"},"remoteAddress":"172.18.0.7","remotePort":36462},"res":{"statusCode":200,"header":null},"msg":"Received request to be handled by a worker. Assigning client to a worker and redirecting request to it.","time":"2018-07-20T06:56:04.284Z","v":0}
{"name":"graphistry","metadata":{"userInfo":{}},"hostname":"cbf3628eef58","pid":32,"module":"central","fileName":"central/lib/worker-router.js","level":30,"workerQuery":[{"_id":"5b517fb06e07e97d5d93bf22","ip":"localhost","pid":66,"port":10020,"active":false,"updated":"2018-07-20T06:56:02.629Z"},{"_id":"5b517fb06e07e97d5d93bf23","ip":"localhost","pid":35,"port":10005,"active":false,"updated":"2018-07-20T06:56:02.630Z"},{"_id":"5b517fb06e07e97d5d93bf25","ip":"localhost","pid":52,"port":10002,"active":false,"updated":"2018-07-20T06:56:02.673Z"},{"_id":"5b517fb06e07e97d5d93bf24","ip":"localhost","pid":164,"port":10010,"active":false,"updated":"2018-07-20T06:56:02.683Z"},{"_id":"5b517fb06e07e97d5d93bf28","ip":"localhost","pid":93,"port":10029,"active":false,"updated":"2018-07-20T06:56:02.690Z"},
...
{"_id":"5b517fb16e07e97d5d93bf40","ip":"localhost","pid":216,"port":10027,"active":false,"updated":"2018-07-20T06:56:04.020Z"},{"_id":"5b517fb16e07e97d5d93bf3f","ip":"localhost","pid":67,"port":10021,"active":false,"updated":"2018-07-20T06:56:04.047Z"},{"_id":"5b517fb16e07e97d5d93bf41","ip":"localhost","pid":211,"port":10018,"active":false,"updated":"2018-07-20T06:56:04.101Z"}],"workerLastAssigned":{"localhost:10004":"2018-07-20T06:31:49.961Z","localhost:10009":"2018-07-20T06:39:05.989Z"},"msg":"Queried database for available workers to pick for routing request","time":"2018-07-20T06:56:04.286Z","v":0}
{"name":"graphistry","metadata":{"userInfo":{}},"hostname":"cbf3628eef58","pid":32,"module":"central","fileName":"central/lib/worker-router.js","level":30,"workerLastAssigned":{"localhost:10004":"2018-07-20T06:31:49.961Z","localhost:10009":"2018-07-20T06:39:05.989Z"},"msg":"Checking available workers last assigned time","time":"2018-07-20T06:56:04.286Z","v":0}
...
{"name":"graphistry","metadata":{"userInfo":{}},"hostname":"cbf3628eef58","pid":32,"module":"central","fileName":"central/lib/worker-router.js","level":20,"msg":"Assigning worker on localhost, port 10020","time":"2018-07-20T06:56:04.287Z","v":0}
{"name":"graphistry","metadata":{"userInfo":{}},"hostname":"cbf3628eef58","pid":32,"module":"central","fileName":"central/lib/server.js","level":20,"req":{"method":"GET","url":"/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a","headers":{"host":"ec2-35-172-213-119.compute-1.amazonaws.com","x-real-ip":"50.0.128.91","x-forwarded-for":"50.0.128.91","x-forwarded-proto":"http","connection":"close","x-graphistry-prefix":"/worker/","upgrade-insecure-requests":"1","user-agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36","accept":"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8","accept-encoding":"gzip, deflate","accept-language":"en-US,en;q=0.9","cookie":"io=jQsh2lrAOdi17hGJAAAA"},"remoteAddress":"172.18.0.7","remotePort":36462},"worker":{"hostname":"localhost","port":10020,"timestamp":"2018-07-20T06:56:02.629Z"},"redirect":"@worker10020","msg":"Assigned client to worker and redirected request to @worker10020","time":"2018-07-20T06:56:04.287Z","v":0}
```

## Worker Logs

GPU web session workers in debug mode will report they are climed, 


### Session handshakes

```
{...,"msg":"HTTP request received by Express.js { originalUrl: '/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a',\n  url: '/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a',\n  method: 'GET' }","time":"2018-07-20T06:56:04.301Z","v":0}
{...,"active":true,"msg":"Reporting worker is active.","time":"2018-07-20T06:56:04.336Z","v":0}

{...,"module":"serv...,"req":{"method":"GET","url":"/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a","headers":{"host":"...","x-real-ip":"...", ...},"msg":"Client has connected with clientId: 4425d4d87889f9bc","time":"2018-07-20T06:56:04.338Z","v":0}

{...,"req":{"method":"GET","url":"/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a","headers":{"host":"...","x-real-ip":"...", ...},"base":"/worker/10020/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a","prefix":"/worker/10020","msg":"Resolved proxy paths","time":"2018-07-20T06:56:04.340Z","v":0}
```

### Start hydrating session workbook, GPU configuration

```
{...,"err":{"message":"ENOENT: no such file or directory, stat '/tmp/graphistry/workbook_cache/Workbooks%2F4425d4d6a7b26f5a%2Fworkbook.json.e3282cc1f4c2c021bf66ce478d85b6eb35e1e939'","name":"Error","stack":"Error: ENOENT: no such file or directory, stat '/tmp/graphistry/workbook_cache/Workbooks%2F4425d4d6a7b26f5a%2Fworkbook.json.e3282cc1f4c2c021bf66ce478d85b6eb35e1e939'","code":"ENOENT","stackArray":[]},"msg":"No matching file found in cache Workbooks/4425d4d6a7b26f5a/workbook.json","time":"2018-07-20T06:56:05.598Z","v":0}
{...,"err":{"message":"Missing credentials in config","name":"Error","stack":"Error: Missing credentials in config\n    at IncomingMessage.<anonymous> (/var/graphistry/packages/viz-app/node_modules/@graphistry/config/node_modules/aws-sdk/lib/util.js:847:34)\n    at IncomingMessage.emit (events.js:130:15)\n    at IncomingMessage.emit (domain.js:421:20)\n    at endReadableNT (_stream_readable.js:1101:12)\n    at process._tickCallback (internal/process/next_tick.js:152:19)","code":"CredentialsError","stackArray":[{"file":"/var/graphistry/packages/viz-app/node_modules/@graphistry/config/node_modules/aws-sdk/lib/util.js","line":847,"column":34,"function":"IncomingMessage.<anonymous>"},{"file":"events.js","line":130,"column":15,"function":"IncomingMessage.emit"},{"file":"domain.js","line":421,"column":20,"function":"IncomingMessage.emit"},{"file":"_stream_readable.js","line":1101,"column":12,"function":"endReadableNT"},{"file":"internal/process/next_tick.js","line":152,"column":19,"function":"process._tickCallback"}]},"msg":"Could not load specified workbook, continuing with fresh workbook","time":"2018-07-20T06:56:05.617Z","v":0}

{...,"layoutAlgorithms":[{"params":{"tau":{"type":"discrete","displayName":"Precision vs. Speed","value":0,"min":-5,"max":5},"gravity":{"scale":"log","type":"continuous","displayName":"Center Magnet","value":1},"scalingRatio":{"scale":"log","type":"continuous","displayName":"Expansion Ratio","value":1},"edgeInfluence":{"type":"discrete","displayName":"Edge Influence","value":0,"min":0,"max":5,"step":1},"strongGravity":{"type":"bool","displayName":"Compact Layout","value":false},"dissuadeHubs":{"type":"bool","displayName":"Dissuade Hubs","value":false},"linLog":{"type":"bool","displayName":"Strong Separation (LinLog)","value":false},"lockedX":{"type":"bool","displayName":"Locked X coordinates","value":false},"lockedY":{"type":"bool","displayName":"Locked Y coordinates","value":false}}}],"msg":"Instantiating layout algorithms","time":"2018-07-20T06:56:05.628Z","v":0}
{...,"msg":"Attempted to send falcor update, but no socket connected yet.","time":"2018-07-20T06:56:05.646Z","v":0}
```

### Load data into backend

```
{"name":"Facebook","metadata":{....,"type":"default","scene":"default","mapper":"default","device":"default","vendor":"default","controls":"default","id":"4425d4daf8b79553","dataset":"Facebook","workbook":"4425d4d6a7b26f5a","url":"Facebook","msg":"Attempting to load dataset","time":"2018-07-20T06:56:05.829Z","v":0}
{...,"msg":"Cannot fetch headers from S3, falling back on cache","time":"2018-07-20T06:56:05.834Z","v":0}
{...,"msg":"Found up-to-date file in cache Facebook","time":"2018-07-20T06:56:05.835Z","v":0}
{...,"msg":"Attempted to send falcor update, but no socket connected yet.","time":"2018-07-20T06:56:05.844Z","v":0}
{...,"msg":"Decoding VectorGraph (version: 0, name: , nodes: 4039, edges: 88234)","time":"2018-07-20T06:56:05.906Z","v":0}
{...,"msg":"Attempted to send falcor update, but no socket connected yet.","time":"2018-07-20T06:56:05.907Z","v":0}
...
{...,"attributes":["label","community_louvain","degree","indegree","outdegree","community_spinglass","community_infomap","closeness","betweenness","pagerank"],"msg":"Successfully loaded dataframe","time":"2018-07-20T06:56:05.914Z","v":0}
{...,"msg":"Attempted to send falcor update, but no socket connected yet.","time":"2018-07-20T06:56:05.922Z","v":0}
{...,"msg":"Skipping unmapped attribute label","time":"2018-07-20T06:56:05.955Z","v":0}
```

### Load data into GPU

```
{...,"msg":"Attempted to send falcor update, but no socket connected yet.","time":"2018-07-20T06:56:05.955Z","v":0}
{...,"msg":"Number of points in simulation: 4039","time":"2018-07-20T06:56:05.958Z","v":0}
{...,"msg":"Creating buffer curPoints, size 32312","time":"2018-07-20T06:56:05.959Z","v":0}
{...,"msg":"Creating buffer nextPoints, size 32312","time":"2018-07-20T06:56:05.959Z","v":0}
{...,"msg":"Attempted to send falcor update, but no socket connected yet.","time":"2018-07-20T06:56:05.960Z","v":0}
{...,"msg":"Number of edges: 88234","time":"2018-07-20T06:56:05.973Z","v":0}


{...,"msg":"Dataset    nodes:4039  edges:176468  splits:%d","time":"2018-07-20T06:56:06.288Z","v":0}
{...,"msg":"Number of midpoints:  0","time":"2018-07-20T06:56:06.288Z","v":0}
{...,"msg":"Number of edges in simulation: 88234","time":"2018-07-20T06:56:06.289Z","v":0}
{...,"msg":"Creating buffer degrees, size 16156","time":"2018-07-20T06:56:06.289Z","v":0}
...
{...,"memFlags":1,"map":[1],"msg":"Flags set","time":"2018-07-20T06:56:06.297Z","v":0}
{...,"msg":"Attempted to send falcor update, but no socket connected yet.","time":"2018-07-20T06:56:06.299Z","v":0}


{...,"msg":"Updating simulation settings { simControls: { ForceAtlas2Barnes: { tau: 0 } } }","time":"2018-07-20T06:56:06.331Z","v":0}
```

### Run default backend data pipeline

```
{...,"msg":"Starting Filtering Data In-Place by DataframeMask","time":"2018-07-20T06:56:06.383Z","v":0}
```

### Connect to browser socket (post-UI-load)

```
{...,"msg":"Socket connected before timeout","time":"2018-07-20T06:56:06.784Z","v":0}
{...,"req":{"method":"GET","url":"/socket.io/?dataset=Facebook&workbook=4425d4d6a7b26f5a&EIO=3&transport=polling&t=MIsUMOp","headers":{"host":"ec2-35-172-213-119.compute-1.amazonaws.com","x-real-ip":"50.0.128.91","x-forwarded-for":"50.0.128.91","x-forwarded-proto":"http","connection":"close","x-graphistry-prefix":"/worker/10020","accept":"*/*","user-agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36","referer":"http://ec2-35-172-213-119.compute-1.amazonaws.com/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a","accept-encoding":"gzip, deflate","accept-language":"en-US,en;q=0.9","cookie":"io=jQsh2lrAOdi17hGJAAAA"},"remoteAddress":"172.18.0.7","remotePort":49762},"remoteAddress":"172.18.0.7","msg":"Connection Info","time":"2018-07-20T06:56:06.786Z","v":0}
{...,"fileName":"graph-viz/viz-server.js","socketID":"9ckImeuIxO_97olrAAAA","level":30,"msg":"Client connected","time":"2018-07-20T06:56:06.786Z","v":0}
```

###  Send browser instance state
```
{...,"module":"viz-app/worker/services/sendFalcorUpdate.js","level":20,"jsonGraph":{"workbooksById":{"4425d4d6a7b26f5a":{"viewsById":{"4425d4daf96bbb8e":{"columns":{"length":19,"time":{"length":0}},"histograms":{"length":1},"timebars":{"length":0,"controls":{"0":{"enabled":false}}},"inspector":{"tabs":{"length":2}},"scene":{"renderer":{"edges":{"elements":88234},"points":{"elements":4039}}}}}}}},"paths":[["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e",["columns","histograms","timebars"],"length"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","columns","time","length"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","inspector","tabs","length"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","scene","renderer",["edges","points"],"elements"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","timebars","controls",0,"enabled"]],"invalidated":[["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","encodings"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","columns","length"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","columns","time","length"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","inspector","rows"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","histogramsById"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","timebarsById"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","timebars","controls",0,"enabled"],["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e",["labelsByType","componentsByType"]]],"msg":"sending falcor update","time":"2018-07-20T06:56:06.791Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/graph/img/logo_white_horiz.png',\n  url: '/graph/img/logo_white_horiz.png',\n  method: 'GET' }","time":"2018-07-20T06:56:07.356Z","v":0}
```

### Send browser the initial visual graph
```
{...,"module":"viz-app/worker/services/sendFalcorUpdate.js","level":20,"jsonGraph":{"workbooksById":{"4425d4d6a7b26f5a":{"viewsById":{"4425d4daf96bbb8e":{"session":{"message":"Loading graph","progress":100,"status":"init"}}}}}},"paths":[["workbooksById","4425d4d6a7b26f5a","viewsById","4425d4daf96bbb8e","session",["message","progress","status"]]],"invalidated":[],"msg":"sending falcor update","time":"2018-07-20T06:56:08.691Z","v":0}


{...,"activeBuffers":["curPoints","pointSizes","logicalEdges","forwardsEdgeToUnsortedEdge","edgeColors","pointColors","forwardsEdgeStartEndIdxs"],"activeTextures":[],"activePrograms":["pointpicking","pointsampling","midedgeculled","edgepicking","arrowculled","arrowhighlight","edgehighlight","arrowselected","edgeselected","radialaxes","pointculledoutline","pointculled","fullscreen","fullscreenDummy","fullscreenDark","pointselectedoutline","pointselected","pointhighlightoutline","pointhighlight"],"msg":"Beginning stream","time":"2018-07-20T06:56:09.861Z","v":0}
{...,"msg":"CLIENT STATUS true","time":"2018-07-20T06:56:09.861Z","v":0}
{...,"counts":{"num":4039,"offset":0},"msg":"Copying hostBuffer[pointSizes]. Orig Buffer len:  4039","time":"2018-07-20T06:56:09.870Z","v":0}
{...,"msg":"constructor:  function Uint8Array() { [native code] }","time":"2018-07-20T06:56:09.870Z","v":0}
{...,"counts":{"num":176468,"offset":0},"msg":"Copying hostBuffer[logicalEdges]. Orig Buffer len:  176468","time":"2018-07-20T06:56:09.872Z","v":0}
{...,"msg":"constructor:  function Uint32Array() { [native code] }","time":"2018-07-20T06:56:09.872Z","v":0}
{...,"counts":{"num":88234,"offset":0},"msg":"Copying hostBuffer[forwardsEdgeToUnsortedEdge]. Orig Buffer len:  88234","time":"2018-07-20T06:56:09.874Z","v":0}
{...,"msg":"constructor:  function Uint32Array() { [native code] }","time":"2018-07-20T06:56:09.874Z","v":0}
{...,"counts":{"num":176468,"offset":0},"msg":"Copying hostBuffer[edgeColors]. Orig Buffer len:  176468","time":"2018-07-20T06:56:09.881Z","v":0}
{...,"msg":"constructor:  function Uint32Array() { [native code] }","time":"2018-07-20T06:56:09.881Z","v":0}
{...,"counts":{"num":4039,"offset":0},"msg":"Copying hostBuffer[pointColors]. Orig Buffer len:  4039","time":"2018-07-20T06:56:09.881Z","v":0}
{...,"msg":"constructor:  function Uint32Array() { [native code] }","time":"2018-07-20T06:56:09.881Z","v":0}
{...,"counts":{"num":8078,"offset":0},"msg":"Copying hostBuffer[forwardsEdgeStartEndIdxs]. Orig Buffer len:  8078","time":"2018-07-20T06:56:09.881Z","v":0}
{...,"msg":"constructor:  function Uint32Array() { [native code] }","time":"2018-07-20T06:56:09.882Z","v":0}
{...,"msg":"selectNodesInRect { all: true }","time":"2018-07-20T06:56:09.899Z","v":0}
{...,"msg":"selectNodesInRect { all: true }","time":"2018-07-20T06:56:09.915Z","v":0}
{...,"module":"viz-app/worker/services/sendFalcorUpdate.js","level":20,"jsonGraph":{"workbooks":{"open":{"$type":"ref","value":["workbooksById","4425d4d6a7b26f5a"]}},"workbooksById":{"4425d4d6a7b26f5a":{"viewsById":{"4425d4daf96bbb8e":{"session":{"message":null,"progress":100,"status":"init"}}}}}},"paths":[["workbooks","open","viewsById","4425d4daf96bbb8e","session",["message","progress","status"]]],"invalidated":[],"msg":"sending falcor update","time":"2018-07-20T06:56:10.069Z","v":0}
{...,"msg":"CLIENT STATUS false","time":"2018-07-20T06:56:10.088Z","v":0}
{...,"msg":"selectNodesInRect { all: true }","time":"2018-07-20T06:56:10.317Z","v":0}


{...,"msg":"selectNodesInRect { all: true }","time":"2018-07-20T06:56:10.317Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=curPoints',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=curPoints',\n  method: 'GET' }","time":"2018-07-20T06:56:10.362Z","v":0}
{...,"msg":"HTTP GET request for vbo curPoints","time":"2018-07-20T06:56:10.363Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=pointSizes',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=pointSizes',\n  method: 'GET' }","time":"2018-07-20T06:56:10.364Z","v":0}
{...,"msg":"HTTP GET request for vbo pointSizes","time":"2018-07-20T06:56:10.364Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=forwardsEdgeToUnsortedEdge',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=forwardsEdgeToUnsortedEdge',\n  method: 'GET' }","time":"2018-07-20T06:56:10.364Z","v":0}
{...,"msg":"HTTP GET request for vbo forwardsEdgeToUnsortedEdge","time":"2018-07-20T06:56:10.365Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=logicalEdges',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=logicalEdges',\n  method: 'GET' }","time":"2018-07-20T06:56:10.365Z","v":0}
{...,"msg":"HTTP GET request for vbo logicalEdges","time":"2018-07-20T06:56:10.366Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=edgeColors',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=edgeColors',\n  method: 'GET' }","time":"2018-07-20T06:56:10.366Z","v":0}
{...,"msg":"HTTP GET request for vbo edgeColors","time":"2018-07-20T06:56:10.367Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=pointColors',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=pointColors',\n  method: 'GET' }","time":"2018-07-20T06:56:10.369Z","v":0}
{...,"msg":"HTTP GET request for vbo pointColors","time":"2018-07-20T06:56:10.369Z","v":0}
{...,"msg":"selectNodesInRect { all: true }","time":"2018-07-20T06:56:10.371Z","v":0}


{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=forwardsEdgeStartEndIdxs',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=forwardsEdgeStartEndIdxs',\n  method: 'GET' }","time":"2018-07-20T06:56:10.606Z","v":0}
{...,"msg":"HTTP GET request for vbo forwardsEdgeStartEndIdxs","time":"2018-07-20T06:56:10.606Z","v":0}


{...,"msg":"CLIENT STATUS true","time":"2018-07-20T06:56:20.319Z","v":0}
{...,"msg":"CLIENT STATUS false","time":"2018-07-20T06:56:20.413Z","v":0}
```

### Run iterative clustering and stream results to client

``` 
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=curPoints',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=curPoints',\n  method: 'GET' }","time":"2018-07-20T06:56:20.837Z","v":0}
{...,"msg":"HTTP GET request for vbo curPoints","time":"2018-07-20T06:56:20.837Z","v":0}
{...,"msg":"CLIENT STATUS true","time":"2018-07-20T06:56:25.821Z","v":0}
{...,"msg":"CLIENT STATUS false","time":"2018-07-20T06:56:25.841Z","v":0}
{...,"msg":"HTTP request received by Express.js { originalUrl: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=curPoints',\n  url: '/vbo?id=9ckImeuIxO_97olrAAAA&buffer=curPoints',\n  method: 'GET' }","time":"2018-07-20T06:56:26.444Z","v":0}
{...,"msg":"HTTP GET request for vbo curPoints","time":"2018-07-20T06:56:26.445Z","v":0}


{...,"msg":"CLIENT STATUS true","time":"2018-07-20T06:56:29.099Z","v":0}
{...,"module":"viz-app/worker/services/sendFalcorUpdate.js","level":20,"jsonGraph":{"workbooks":{"open":{"$type":"ref","value":["workbooksById","4425d4d6a7b26f5a"]}},"workbooksById":{"4425d4d6a7b26f5a":{"viewsById":{"4425d4daf96bbb8e":{"session":{"message":null,"progress":100,"status":"init"}}}}}},"paths":[["workbooks","open","viewsById","4425d4daf96bbb8e","session",["message","progress","status"]]],"invalidated":[],"msg":"sending falcor update","time":"2018-07-20T06:56:29.302Z","v":0}
```

### End session



```
{...,"req":{"method":"GET","url":"/graph/graph.html?dataset=Facebook&workbook=4425d4d6a7b26f5a","headers":{"host":"...","x-real-ip":"...", ...},"msg":"User disconnected from socket","time":"2018-07-20T06:57:43.135Z","v":0}
{...,"active":false,"msg":"Reporting worker is inactive.","time":"2018-07-20T06:57:43.135Z","v":0}
{...,"msg":"Attempting to exit worker process.","time":"2018-07-20T06:57:43.135Z","v":0}
```

### Replacement worker starts as a fresh process / pid


```
{...."msg":"Config options resolved","time":"2018-07-20T06:57:49.471Z","v":0}
...
```
