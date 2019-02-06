# Manual inspection of all key running components

Takes about 5-10min

## 0. Start

* Put the container in `/var/home/my_user/releases/my_release_1`: Ensures relative paths work, and good persistence hygiene across upgrades
* Go time!
```
docker load -i containters.tar
docker-compose up
```

## 1. Static assets

* Go to http://graphistry
* Expect to see something similar to http://labs.graphistry.com
* Good way to check for TLS and container load failures

## 2. Visualization of preloaded dataset 

* Go to http://graphistry/graph/graph.html?dataset=Facebook
  * Can also get by point-and-clicking if URL is uncertain: http://graphistry -> `Learn More` -> (the page)
* Expect to see something similar to http://labs.graphistry.com/graph/graph.html?dataset=Facebook
  * If points do not load, or appear and freeze, likely issues with GPU init (driver) or websocket (firewall)
  * Can also be because preloaded datasets are unavailable: not provided, or externally mounted data sources
    * In this case, use ETL test, and ensure clustering runs for a few seconds (vs. just initial pageload)
  
## 3a. Test `/etl` and PyGraphistry

Do via notebook if possible, else `curl`

* Get API key by running from host:

```
docker-compose exec central curl -s http://localhost:10000/api/internal/provision?text=MYUSERNAME
```

* Install PyGraphistry and check recent version number (Latest: https://pypi.org/project/graphistry/)

```
!pip install graphistry -q
import graphistry
graphistry.__version__
```

* Try your key, will complain if invalid, otherwise silent

```
graphistry.register(protocol='http', server='my.server.com', key='my_key')
```

* Try upload and viz, may need to open result in new tab if HTTPS notebook for HTTP graphistry. Expect to see a triangle:

```
import pandas as pd
df = pd.DataFrame({'s': [0,1,2], 'd': [1,2,0]})
graphistry.bind(source='s', destination='d').plot(df)
```

## 3b. Test `/etl` by commandline

If you cannot do **3a**, test from the host via `curl` or `wget`:

* Make `samplegraph.json`:

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

* Get API key

```
docker-compose exec central curl -s http://localhost:10000/api/internal/provision?text=MYUSERNAME
```

* Run ETL

```
curl -H "Content-type: application/json" -X POST -d @samplegraph.json https://labs.graphistry.com/etl?key=YOUR_API_KEY_HERE
```

* From response, go to corresponding http://graphistry/graph/graph.html?dataset=... 
  * check the viz loads 
  * check the GPU iteratively clusters


## 4. Test pivot

### 4a. Basic
* Test it loads at http://graphistry/pivot
* Connector page only shows WHOIS and HTTP pivots (http://graphistry/pivot/connectors), and clicking them returns green

### 4b. Investigation page

* Starts empty at http://graphistry/pivot/home
* Pressing `+` creates a new untitled investigations
* Can create and run a manual pivot in it, with settings:
```
Pivot: Enter data
Events: [ { "x": 1, "y": "b"} ]
Nodes: x y
  * Expect to see a graph with 1 event node, and 2 connected entity nodes `1` and `b`
```

### 4c. Configurations

* Edit `.env` and `docker-compose.yml` as per below
  * Set each config in one go so you can test more quickly, vs start/stop. 
* Run
```
docker-compose down
docker-compose up
```

#### 4c.i Password

* Edit `.env` to uncomment `PIVOT_PASSWORD=something`
* Going to http://graphistry/pivot should now challenge for `graphistry` / `something`

#### 4c.ii Persistence

* Edit `docker-compose.yml` to uncomment `pivot`'s `volume` mounts
* Edit...

#### 4c.iii Splunk

* Edit `.env` for `SPLUNK_HOST`, `SPLUNK_PORT`, `SPLUNK_USER`, `SPLUNK_KEY`
* Run one pivot:
```
Pivot: Search: Splunk
Query: *
Max Results: 2
Entities: *
```
  * Expect to see two orange nodes on the first line, connected to many nodes in the second

#### 4d.iv Neo4j

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
  
#### 4e. ELK

#### 4f. VT 

