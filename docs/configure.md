# Configuring Graphistry

Administrators can add users, specify passwords, TLS/SSL, persist data across sessions, connect to databases, specify ontologies, and more. 

* For a list of many investigation-oriented options, see their [settings reference page](configure-investigation.md).

* See [update, backup, & migration instructions](update-backup-migrate.md) for preserving configurations and  data across installations.

* For advanced Python notebook and application configuration, see [PyGraphistry configuration](configure-pygraphistry.md).

## Add your team and provide API keys

See [user creation docs](user-creation.md)


## Top configuration places: data/config/custom.env, data/pivot-db/config/config.json

* Graphistry is primarily configured through file `data/config/custom.env`
* Connector, ontology, and pivot configuration is optionally via `data/pivot-db/config/config.json`. Many relevant options are [detailed in a reference page](configure-investigation.md).

Between edits, restart one or all Graphistry services: `docker-compose stop`  and `docker-compose up -d`


## Further configuration: docker-compose.yml and Caddyfile

* More advanced administrators may edit `docker-compose.yml` .  Maintenance is easier if you never edit it.
* Custom TLS is via editing `Caddyfile`([Caddy docs](https://caddyserver.com/docs/automatic-https)) and mounting your certificates via `docker-compose.yml` ([Caddy Docker docs](https://github.com/abiosoft/caddy-docker)). Caddy supports LetsEncrypt with automatic renewal, custom certificates and authorities, and self-signed certificates. 

### Setup free Automatic TLS

Caddy supports [free automatic TLS](https://caddyserver.com/docs/automatic-https) as long as your site meets the listed conditions.  

Sample `Caddyfile`:
```
https://*.website.org:443 {
  tls {
    max_certs 100
  }
  proxy / nginx:80 {
    websocket
  }
}
```

Note that Graphistry is internally configured via `nginx`.

### Setup custom certs

* Place your certs in `./.caddy/my.crt` and `./.caddy/my.key`
* Modify `Caddyfile`:

```
https://your.site.ngo:443 {
  tls /root/.caddy/my.crt /root/.caddy/my.key
  proxy / nginx:80 {
    websocket
  }
}
```

Note the use of a fully qualified domain name in the first line, and that the file paths are for the `caddy` container's file system, not the host file system

### Debugging TLS

Custom TLS setups often fail due to the certificate, OS, network, Caddy config, and file permissions. To perform isolated checks on each, try:

* Test the certificate
* Test a [standalone Caddy static file server](https://www.baty.net/2018/using-caddy-for-serving-static-content/)
* ... Including on another box, if OS/network issues are suspected
* Check the logs of `docker-compose logs -f -t caddy nginx`
* Test whether the containers are up and ports match via `docker-compose ps`, `curl`, and `curl` from within a docker container (so within the docker network namespace)

If problems persist, please reach out to your Graphistry counterparts. Additional workarounds are possible.


## Connectors

Optionally, you can configure Graphistry to use database connectors. Graphistry will orchestrate cross-database query generation, pushing them down through the database API, and returning the combined results to the user. This means Graphistry can reuse your existing scaleout infrastructure and make its data more accessible to your users without requiring a second copy to be maintained. Some connectors further support use of the [Graphistry data bridge](bridge.md) for proxying requests between a Graphistry cloud server and an intermediate on-prem data bridge instead of directly connecting to on-prem API servers.

### Security Notes 

* Graphistry only needs `read only` access to the database
* Only one system-wide connector can be used per database per Graphistry virtual server at this time. Ex: You can have Splunk user 1 + Neo4j user 2 on one running Graphistry container, and Splunk user 3 + Neo4j user 2 on another running Graphistry container.
* [Templates](templates.md) and other embedding modes do not require further Graphistry configuration be beyond potentially API key generation. However, Graphistry implementors will still need access to external dashboards, APIs, etc., into which they'll be embedding Graphistry views.

### Get started

1. Edit lines of `data/config/custom.env` corresponding to your connector and restart Graphistry (see `.env` for commented out examples):

```
ES_HOST=...
SPLUNK_HOST=...
```

2. Restart `graphistry`, or at least the `pivot` service:

`docker-compose stop && docker-compose up -d` or `docker-compose stop nginx pivot && docker-compose up -d`

3. Test

* In `/pivot/connectors`, configured databases should appear in the live connectors section, and clicking the status check should turn them green
* Running a sample investigation with a database query should return results



### Example: Splunk

1. Create a restricted Splunk API user role from the Splunk Web UI

* `Settings` -> `Users` -> `Add new`
* Name: any, such as `graphistry_role`
* For `capabilities`: `rest_properties get`, `rtsearch`, `search`
* For `indexes`: Any that you want exposed to the investigtation team

2. Create a restricted Splunk API user from the Splunk Web UI

* `Settings` -> `Users` -> `Add new`
* Record their name/pwd
* Assign them to the role `graphistry_user` from step 1

3. Configure Graphistry's `custom.env` with the Splunk server and user information:

```
### Required
#SPLUNK_HOST=splunk.acme.org
#SPLUNK_USER=admin
#SPLUNK_KEY=...

### Optional
#SPLUNK_SCHEME=https
#SPLUNK_PORT=8089
#SPLUNK_WEB_PORT=443
#SPLUNK_SUFFIX=/en-US
#SPLUNK_CACHE_TIMEOUT=14400
#SPLUNK_SEARCH_MAX_TIME=20
#SPLUNK_USE_PROXY=false
#SPLUNK_PROXY_KEY=...
#SPLUNK_SERVER_KEY=...
```

4. Restart and test the connector as per above. You can test the underlying Splunk API configuration by running `https://splunk.host.name.here:8089/services/search/jobs/export  -d search="search * | head 3" -d output_mode=csv` from your local Splunk server and your Graphistry server.

### Data bridge

In scenarios such as a Graphistry cloud server accessing on-prem API servers, an intermediate on-prem data bridge may be necessary. You can mix bridged and direct (default) connectors in the same Graphistry server. Learn more about the [Graphistry data bridge](bridge.md).

### Variants

* Give your Graphistry implementation user increased permissions so they can embed Graphistry into existing dashbboard and notification systems, such as for embedded visualizations and quicklinks into contextual [investigation templates](templates.md)* Run a [Graphistry data bridge](bridge.md), if available for your connector, which may help with cases such as firewalls preventing incoming connections from Graphistry to your database
* Run a bastion server between Graphistry and your database, such as a new Splunk search head
* Create fine-grained permissions by running multiple Graphistry virtual servers, with a new Splunk role per instance


## Ontology

See [custom ontology extensions](configure-ontology.md) and [settings reference page](configure-investigation.md) for full options. Topics include controlling:

* Map Column -> Type
* Map Type -> color, icon, size
* Map node/edge titles

## Pivots

Every connector comes with a base set of pivots. See [custom pivots](configure-custom-pivots.md) for teaching Graphistry new pivots based on existing connectors and pivots.

## Performance

See also [deployment planning](deployment-planning.md) and [hw/sw planning](hardware-software.md). 

Several common performance tunings are:

* Monitoring GPU use via `nvidia-smi`-based compute/memory tools and standard CPU monitors
* Running one Graphistry install in a server with multiple CPUs and GPUs. Graphistry automatically uses the available resources, and admins can restrict consumption via docker configurations
* Check `LOG_LEVEL` and `GRAPHISTRY_LOG_LEVEL` (`data/config/custom.env`) is set to `INFO` or `ERROR`
* Running multiple API servers by fronting a sticky-session load balancer (nginx, caddy) over multiple Graphistry servers
* Add environment variables to `data/config/custom.env` based on available CPU/GPU cores and memory:
  * GPU live clustering: `STREAMGL_NUM_WORKERS`, defaults to `4`, recommend 1 per 4GB GPU 
  * GPU/CPU analytics:`FORGE_NUM_WORKERS`, defaults to `1`, recommend 1 per 4 GB GPU
  * CPU network streaming and limited analytics: `STREAMGL_CPU_NUM_WORKERS`, defaults to `max`, recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS` (GPU sibling)
  * CPU upload handlers: `PM2_MAX_WORKERS`, defaults to `max`, recommend 1 per 2 CPUs or matching `STREAMGL_NUM_WORKERS`


TLS: Caddyfile
--------------------

All external traffic reverse proxies through Caddy, which is provided as a convenient declarative control layer for settings such as TLS. Please contact your sales engineer for additional assistance. 

### Caddyfile

For automatic TLS (Let's Encrypt) and manual certs, edit `Caddyfile` ([Caddy docs](https://caddyserver.com/docs/tls)) and mount your certs by editing `docker-compose.yml` ([Caddy Docker docs](https://github.com/abiosoft/caddy-docker))

#### Sample free automatically-renewing LetsEncrypt TLS certificates with Caddy

**Caddyfile**

```
*.acme.org {
  tls {
    max_certs 100
  }
  proxy / nginx:80 {
    websocket
  }
}
:80 {
  proxy / nginx:80 {
    websocket
  }
}
```
