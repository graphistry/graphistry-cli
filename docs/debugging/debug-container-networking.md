
# Debugging Container Networking

The following tests may help pinpoint loading failures.

## Prerequisites

Check the main tests (https://github.com/graphistry/graphistry-cli)

* All containers are running
* Healthchecks passes

## Mongo container

### A. Host is running Mongo

*Note*: Database, collection initializated by `launch` (e.g., during `init`) and does not persist between runs.

```
docker exec monolith-network-mongo /bin/bash -c "echo 'db.stats().ok' | mongo localhost/cluster -quiet"
```
=> 
```
1
```

### B. Mongo has registered workers

*Note*: Populated by `monolith-network-viz` on node process start

```
docker exec monolith-network-mongo /bin/bash -c "echo 'db.node_monitor.find()' | mongo localhost/cluster -quiet"
```
=> 10+ workers 
```
{ "_id" : ObjectId("5b4d7049f160a28b5001a6bf"), "ip" : "localhost", "pid" : 9867, "port" : 10011, "active" : true, "updated" : ISODate("2018-07-30T16:18:31.835Z") }
{ "_id" : ObjectId("5b4d727ff160a28b5001a6c3"), "ip" : "localhost", "pid" : 13325, "port" : 10002, "active" : true, "updated" : ISODate("2018-07-30T16:18:30.697Z") }
{ "_id" : ObjectId("5b4d729af160a28b5001a6c4"), "ip" : "localhost", "pid" : 13392, "port" : 10010, "active" : true, "updated" : ISODate("2018-07-30T16:18:32.108Z") }
{ "_id" : ObjectId("5b4d72e0f160a28b5001a6ca"), "ip" : "localhost", "pid" : 13966, "port" : 10001, "active" : true, "updated" : ISODate("2018-07-30T16:18:31.205Z") }
{ "_id" : ObjectId("5b4d7306f160a28b5001a6cc"), "ip" : "localhost", "pid" : 14156, "port" : 10009, "active" : true, "updated" : ISODate("2018-07-30T16:18:31.717Z") }
{ "_id" : ObjectId("5b4d75fff160a28b5001a6d0"), "ip" : "localhost", "pid" : 17872, "port" : 10000, "active" : true, "updated" : ISODate("2018-07-30T16:18:30.618Z") }
...
```


## Browser

### A. Can access site:

Browse to
```
curl http://MY_GRAPHISTRY_SERVER.com/central/healthcheck
```
=>
```
{"success":true,"lookup_id":"<NUMBER>","uptime_ms":<NUMBER>,"interval_ms":<NUMBER>}
```

### B. Browser has web sockets enabled

Passes test at https://www.websocket.org/echo.html

### C. Can follow central redirect:


Open browser developer network analysis panel and visit

```
http://MY_GRAPHISTRY_SERVER.com/graph/graph.html?dataset=Twitter
```
=>
```
302 on `/graph/graph.html?dataset=Twitter
200 on `/graph.graph.html?dataset=Twitter&workbook=<HASH>`
Page UI loads (`vendor.<HASH>.css`, ...)
Socket connects (`/worker/<NUMBER>/socket.io/?dataset=Twitter&...`)
Dataset positions stream in (`/worker/<NUMBER>/vbo?id=<HASH>&buffer=curPoints`)
```

This call sequence stress a lot of the pipeline.

## NGINX

*Note* Assumes underlying containers are fulfilling these requests (see other tests)

### A. Can server central routes

```
curl -s -I localhost/central/healthcheck | grep HTTP
```
=>
```
HTTP/1.1 200 OK
```


### B. Can receive central redirect:

```
curl -s -I localhost/graph/graph.html?dataset=Twitter | grep "HTTP\|Location"
```
=>
```
HTTP/1.1 302 Found
Location: /graph/graph.html?dataset=Twitter&workbook=<HASH>
```

and

```
curl -s -I localhost/graph/graph.html?dataset=Twitter  |  grep "HTTP\|Location"
```
=>
```
HTTP/1.1 302 Found
Location: /graph/graph.html?dataset=Twitter&workbook=<HASH>
```

### C. Can serve worker routes

```
curl -s -I localhost/worker/10000/healthcheck | grep HTTP
```
=>
```
HTTP/1.1 200 OK
```


## Viz container

### A. Container has a running central server 


```
docker exec monolith-network-viz curl -s -I localhost:3000/central/healthcheck | grep HTTP
```
=>
```
HTTP/1.1 200 OK
```

and

```
docker exec monolith-network-viz curl -s -I localhost:3000/graph/graph.html?dataset=Twitter | grep "HTTP\|Location"
```
=>
```
HTTP/1.1 302 Found
Location: /graph/graph.html?dataset=Twitter&workbook=<HASH>
```


### C. Can communicate with Mongo

First find mongo configuration for MONGO_USERNAME and MONGO_PASSWORD:
`docker exec monolith-network-viz cat central-cloud-options.json` or `docker exec  monolith-network-viz ps -eafww | grep central`

Plug those into `<MONGO_USERNAME>` and `<MONGO_PASSWORD>` below:

```
docker exec -w /var/graphistry/packages/central monolith-network-viz node -e "x = require('mongodb').MongoClient.connect('mongodb://<MONGO_USERNAME><MONGO_PASSWORD>@mongo/cluster').then(function (db) { return db.collection('node_monitor').find() }).then(function (cursor) { return cursor.toArray() }).then(console.log.bind(null, 'ok'), console.error.bind(null, 'error'))"
```

=>
```
ok [ { _id: <HASH>,
    ip: 'localhost',
    pid: <NUMBER>,
    port: <NUMBER>,
    active: true,
    updated: <TIME> },
  { _id: <HASH>,
    ip: 'localhost',
    pid: <NUMBER>,
    port: <NUMBER>,
    active: true,
    updated: <TIME> },
...
```

### D. Has running workers

```
docker exec monolith-network-viz curl -s -I localhost:10000/healthcheck | grep HTTP
```
=>
```
HTTP/1.1 200 OK
```
