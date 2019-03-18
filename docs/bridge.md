# Graphistry Data Bridge for Proxying

Graphistry now supports bridged connectors, which eases tasks like crossing from a cloud server to on-premise databases. It is designed to work with enterprise firewall policies such as HTTP-only and outgoing-only.

## Prerequisites

* Running Graphistry server, with admin access
* Proxy installer, access to proxy server, `docker`, and `docker-compose`

## Design

**Graphistry server**

* Bridged connectors: Built into standard Graphistry servers
* Individual database connectors can be configured to use a proxy instead of a direct connection

**Graphistry proxy**

* Separate install: 
* Proxies establish persistent outgoing http/https connections with your Graphistry server. This enables the server to quickly push queries to your proxy.

## Keys

* For each connector, generate unguessable UUIDs for the server and client - this enables either side to trust and revoke access

## Example: Splunk

### Generate a key

Ex: Uisng your Graphistry server:

`docker exec -it ec2-user_pivot_1 node_modules/uuid/bin/uuid v4` => `<my_key_1>`

### Server

In `.env`, setup Splunk connector and set it to bridge via a Graphistry proxy:

```
SPLUNK_HOST=splunk.example.com
SPLUNK_WEB_PORT=3000
SPLUNK_USER=my_user
SPLUNK_KEY=my_pwd
### SPLUNK PROXY ###
SPLUNK_USE_PROXY=true
SPLUNK_SERVER_KEY=my_key_1
SPLUNK_PROXY_KEY=my_key_2
```

### Proxy

Sample edits to `docker-compose.yml`:

```
services:
  agents:
    ...
    environment:
      #REQUIRED: Fill in with your server
      - GRAPHISTRY_HOST=http://graphistry.mysite.com
      #LIKELY: Fill in for connectors this proxy provides
      - SPLUNK_USE_PROXY=true
      - SPLUNK_PROXY_KEY=my_key_2
      - SPLUNK_SERVER_KEY=my_key_1
      #STANDARD      
      - GRAPHISTRY_LOG_LEVEL=DEBUG       
```

## Install and launch proxy

1. Install
```
tar -xvvf proxy.tar.gz
cd proxy
docker load -i proxy.tar
```

2. Configure

Edit `.env` and `docker-compose.yml`. See above example.

3. Launch

```
docker-compose up -d
```

