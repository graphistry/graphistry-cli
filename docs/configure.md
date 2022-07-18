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
* Custom TLS is via editing `Caddyfile`([Caddy docs](https://caddyserver.com/docs/automatic-https)), see below

## SSO

Contact staff for setting up internal SSO (OIDC: Okta, ...) or via social logins to GitHub/Google

If using an external proxy or load balancer, configure Graphistry's site domain setting (see above) and check above TLS settings

Recommendations when self-hosting:
* Setup email
* Mark SSO as site-wide
* Disallow non-SSO account creation


## TLS

We encourage everyone to use HTTPS over HTTP, especially through the automatic TLS option, for [securing authentication](authentication.md)

Graphistry supports both free automatic TLS within your server (Caddy/LetsEncrypt) and offloading to an external load balancer or proxy

### Setup free Automatic TLS

Caddy supports [free automatic TLS](https://caddyserver.com/docs/automatic-https) as long as your site meets the listed conditions.  

Sample `Caddyfile`:
```
https://*.website.org:443 {
  tls {
    max_certs 100
  }
  respond /caddy/health/ 200 {
    body "{\"success\": true}"
    close
  }
  reverse_proxy nginx:80
}
```

Note that Graphistry is internally configured via `nginx`.

### Setup free Semi-Automatic TLS

The above step may fail if your server does not allow outbound internet traffic. To work around, perform a [manual LetsEncrypt Certbot handshake for Caddy](configure-tls-caddy-manual-lets-encrypt-handshake.md).

### Setup custom certs

If you already have certificates, Caddy can use them:

* Place your certs in `./.caddy/my.crt` and `./.caddy/my.key`
* Modify `Caddyfile`:

```
https://your.site.ngo:443 {
  tls /root/.caddy/my.crt /root/.caddy/my.key
  respond /caddy/health/ 200 {
    body "{\"success\": true}"
    close
  }
  reverse_proxy nginx:80
}
```

Note the use of a fully qualified domain name in the first line, and that the file paths are for the `caddy` container's file system, not the host file system

### Setup offloading TLS from a load balancer or proxy

To enforce TLS using your own outside load balancer or proxy rather than the built-in Caddy server, we recommend:

* Setup TLS at your load balancer (ex: AWS ALB) or proxy
* Ensure http traffic is auto-upgraded (redirected) to https
* Forward (stripped) http traffic to Graphistry
* Optionally, in your `Caddyfile`'s [reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy) section, add [trusted_proxies](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#trusted_proxies) so your load balancer's `X-Forwarded-{For,Proto,Host}` headers are trusted for propagation to Graphistry

IP List:

```
reverse_proxy 172.16.0.169:8080 {
	trusted_proxies 173.245.48.0/20 103.21.244.0/22
}
```

Shortcut for internal IPs:

```
reverse_proxy 172.16.0.169:8080 {
	trusted_proxies private_ranges
}
```


### Debugging TLS

Custom TLS setups often fail due to the certificate, OS, network, Caddy config, and file permissions. To perform isolated checks on each, try:

* Test the certificate
* Test a [standalone Caddy static file server](https://www.baty.net/2018/using-caddy-for-serving-static-content/)
* ... Including on another box, if OS/network issues are suspected
* Check the logs of `docker-compose logs -f -t caddy nginx`
* Test whether the containers are up and ports match via `docker-compose ps`, `curl`, and `curl` from within a docker container (so within the docker network namespace)

If problems persist, please reach out to your Graphistry counterparts. Additional workarounds are possible.


## Email

*Optional*

Contact staff for information on using an SMTP-based email service or Mailgun API, which is useful for tasks like user notifications

## Site domain

*Optional*

In the Admin portal, go to Sites and change the `Domain name` to your domain, such as `graphs.acme-corp.com` 

This aids scenarios such as when using an outside proxy and ensuring that web users see the intended external domain instead of the internal one leaking through

## Reverse proxy

### Built-in proxying

Graphistry routes all public traffic through Docker container Caddy, so you generally modify Docker settings for service `caddy:` in `docker-compose.yml` (or `data/config/custom.env`)  or Caddy settings in `data/config/Caddyfile`. Further internal proxying may occur, but we do not advise manipulating internal tiers.

### External proxies

You may externally redirect traffic, such as through an AWS Load Balancer or CloudFlare

* See above TLS discussion
* Set the Site  


### Change public port

If `80` / `443` are already taken, such as when running multiple Graphistry instances on the same box, you may want to change to another port. For example, to expose public port `8888` for Graphistry's HTTP traffic instead of `80`, configure `docker-compose.yml` to map it as follows:

```yml
  caddy:
    ...
    expose:
      - "8888"
    ports:
      - 8888:80
```      

### Reuse Graphistry reverse proxy and JWT auth as a bastion for other services

You can configure the Caddy service to also reverse proxy additional services, including requiring their users to log in with Graphistry account credentials. 

For an example of both public and log-required proxies, see the [graph-app-kit sample](https://github.com/graphistry/graph-app-kit/blob/master/src/caddy/full.Caddyfile).


## Dashboards

Separately [configure the public and private dashboards](configure-dashboards.md)

## Connectors

Optionally, you can configure Graphistry to use database connectors. Graphistry will orchestrate cross-database query generation, pushing them down through the database API, and returning the combined results to the user. This means Graphistry can reuse your existing scaleout infrastructure and make its data more accessible to your users without requiring a second copy to be maintained. Some connectors further support use of the [Graphistry data bridge](bridge.md) for proxying requests between a Graphistry cloud server and an intermediate on-prem data bridge instead of directly connecting to on-prem API servers.

### Security Notes 

* Graphistry only needs `read only` access to the database
* Only one system-wide connector can be used per database per Graphistry virtual server at this time. Ex: You can have Splunk user 1 + Neo4j user 2 on one running Graphistry container, and Splunk user 3 + Neo4j user 2 on another running Graphistry container.
* [Templates](templates.md) and other embedding modes do not require further Graphistry configuration be beyond potentially API key generation. However, Graphistry implementors will still need access to external dashboards, APIs, etc., into which they'll be embedding Graphistry views.

### Get started

1. Edit lines of `data/config/custom.env` corresponding to your connector and restart Graphistry (see `.env` for commented out examples):

```bash
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

```bash
### Required
SPLUNK_HOST=splunk.acme.org
SPLUNK_USER=admin
SPLUNK_KEY=...

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

4. Restart and test the connector as per above. You can test the underlying Splunk API configuration by running `curl -u admin:changme  https://splunk.host.name.here:8089/services/search/jobs/export  -d search="search * | head 3" -d output_mode=csv` from your local Splunk server and your Graphistry server.

### Example: Neo4j

1. Configure Graphistry's `data/pivot-db/config/config.json` with the Neo4j server and user information:

```json
{
    "neo4j": {
        "user": "neo4j",
        "password": "myneo4juser",
        "bolt": "bolt://my.neo4j.com:4687"
    }
}
```

For faster start, or to be explicit about schema, or avoid start issues, you may choose to skip schema inference and optionally provide your own:

```json
{
    "neo4j": {
        "user": "neo4j",
        "password": "myneo4juser",
        "bolt": "bolt://my.neo4j.com:4687",
        "searchMaxTime": 5000,
        "schema": {
            "inferSchema": true,
            "labelProperties": {
                "MyLabel1": [ "my_field_1", "my_field_2" ],
                "MyLabel2": [ "my_field_1", "my_field_3" ],
                "MyLabel3": [ ]
            },
            "relationshipProperties": {
                "MY_RELN_1": [ "my_field_4" ],
                "MY_RELN_2": []
            },
            "defaultTimeIndex": {
                "nodeProperties": ["my_field2"]
            }
        }
    }
}
```


2. Restart and test the connector as per above. In-tool, you can test the connection status for the connector panel by clicking the 'check status' button for the Neo4j connector. If there is an error, you can further test your Neo4j database network connectivity by trying a Graphistry Jupyter notebook demo for Neo4j to connect to Neo4j from the notebook.


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

See [performance tuning](performance-tuning.md)

