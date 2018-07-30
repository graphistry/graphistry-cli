
# Debugging Container Networking

The following tests may help pinpoint loading failures:

## Prerequisites

Check the main tests (https://github.com/graphistry/graphistry-cli)

* All containers are running
* Healthchecks passes

## Mongo container

### A. Host is running Mongo

```
docker exec MONGO_CONTAINER_ID /bin/bash -c "echo 'db.stats().ok' | mongo localhost/cluster -quiet"
```
=> 
```
1
```

### B. Mongo has workers

```
 docker exec  MONGO_CONTAINER_ID /bin/bash -c "echo 'db.node_monitor.find()' | mongo localhost/cluster -quiet"
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

### A. Can read central:

```
http://labs.graphistry.com/central/healthcheck
```
=>
```
{"success":true,"lookup_id":"8469333535151313","uptime_ms":2553188560,"interval_ms":4677}
```

### B. Can receive central redirect:

```
curl -I labs.graphistry.com/graph/graph.html?dataset=Twitter
```
=>
```
302 with location `/graph/graph.html?dataset=Twitter&workbook=<HASH>`
```

### C. Browser has web sockets enabled

Passes test at https://www.websocket.org/echo.html


## Viz container

### A. Container has a running central server 

The host gets a 302 on `docker exec 507092d84cd3 curl -I localhost:3000/graph/graph.html?dataset=Twitter`

### B. Container server is externally accessible

The host gets a 302 on `curl -I localhost:80/graph/graph.html?dataset=Twitter`

In both A. and B. cases, the 302 result appends `...&workbook=HASH`.

### C. Can communicate with Mongo

First find mongo configuration for MONGO_DATABASE, MONGO_USERNAME, MONGO_PASSWORD:
`docker exec  VIZ_CONTAINER_ID cat central-cloud-options.json` or `docker exec  VIZ_CONTAINER_ID ps -eafww | grep central`

Next check that mongo results are viewable:

```
docker exec -w /var/graphistry/packages/central VIZ_CONTAINER_ID node -e "x = require('mongodb').MongoClient.connect('mongodb://MONGO_USERNAMEMONGO_PASSWORD@mongo/cluster').then(function (db) { return db.db('cluster') }).then(function (db) { return db.collection('node_monitor').find() }).then(function (cursor) { return cursor.toArray() }).then(console.log.bind(null, 'ok'), console.error.bind(null, 'error'))"
```

=>
```
ok [ { _id: 5b4d7049f160a28b5001a6bf,
    ip: 'localhost',
    pid: 9867,
    port: 10011,
    active: true,
    updated: 2018-07-30T17:44:35.112Z },
  { _id: 5b4d727ff160a28b5001a6c3,
    ip: 'localhost',
    pid: 13325,
    port: 10002,
    active: true,
    updated: 2018-07-30T17:44:36.763Z },
...
```


