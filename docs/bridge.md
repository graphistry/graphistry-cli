# Graphistry Data Bridge for Proxying

Graphistry supports bridged connectors, which eases tasks like crossing from a cloud server to on-prem databases. It is designed to work with enterprise firewall policies such as HTTP-only and outgoing-only. Instead of Graphistry directly making requests against API servers, Graphistry sends the requests to the data bridge server, which then proxies the query and sends the results back. Graphistry can run a mixture of direct and bridged connectors.

## Prerequisites

* Standard Graphistry GPU application server (ex: cloud), with admin access
* Data bridge docker container (bridge.tar)
* Server to use as a bridge (typically on-prem), with admin access
- CPU-only OK
- Linux:`docker` and `docker-compose`
* Firewall permissions between DB <> bridge and bridge <> Graphistry

## Architecture

**Graphistry GPU application server**

* Bridge-mode connectors: Built into standard Graphistry servers
* Individual database connectors can be configured to use a bridged connector instead of a direct API connector

**Graphistry data bridge server**

* Separate install 
* Proxies establish persistent outgoing http/https connections with your Graphistry server. This enables the server to quickly push queries to your proxy.

## Key configuration

* For each connector, set unguessable UUID strings for the server and client - this enables either side to trust and revoke access. These go in the bridge's `connector.env` and the main application server's `.env`
* Revocation can occur by server or client due to use of 2 keys

## Example: Splunk

### Generate a key

* Can be any string
* Ex: Unguessable strings via `docker-compose exec pivot /bin/bash -c "../../../node_modules/uuid/bin/uuid v4"` => `<my_key_1>`

### Graphistry GPU application server

* Configure: In `.env`, setup the Splunk connector as usual and then set `SPLUNK_USE_PROXY` and the two keys to proxy through a data bridge server:

```
### Splunk connector config
SPLUNK_HOST=splunk.example.com
SPLUNK_WEB_PORT=3000
SPLUNK_USER=my_user
SPLUNK_KEY=my_pwd

### Splunk bridge settings
SPLUNK_USE_PROXY=true
SPLUNK_SERVER_KEY=my_key_1
SPLUNK_PROXY_KEY=my_key_2
```

* Launch: Restart Graphistry via `docker-compose stop pivot && docker-compose up -d pivot`. 

The connector will start looking for the data bridge.

* Test: In the connector settings panel of `/pivot/home`, click the `check status` button for the connector. It should report success and turn green if it  successfully exchanges keys with your bridge and runs a proxied connector command

### Graphistry data bridge server

Edit `connector.env`:

```
#REQUIRED: Fill in with your server
GRAPHISTRY_HOST=https://graphistry.mysite.com

#LIKELY: Fill in for connectors this proxy provides
SPLUNK_USE_PROXY=true
SPLUNK_PROXY_KEY=my_key_2
SPLUNK_SERVER_KEY=my_key_1
```

If your Graphistry instance uses a non-standard prefix, set `GRAPHISTRY_MOUNT_POINT=/my_subdir`

## Install and launch data bridge

1. Install
```
tar -xvvf bridge.tar.gz
cd bridge
docker load -i bridge.tar
```

2. Configure

Edit `.env`. See above example.

3. Launch

```
docker-compose up -d
```

The data bridge will autoconnect to your Graphistry application server. 

4. Test

See `test` section for the Graphistry GPU application server.

5. Debug

Enable the below in the data bridge's `connector.env` and restart it:

```   
DEBUG=*
GRAPHISTRY_LOG_LEVEL=TRACE
```

Watch your bridge's logs and your app server's logs: `docker-compose logs -f -t --tail=1`
