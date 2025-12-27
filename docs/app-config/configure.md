# Configuring Graphistry

Administrators can add users, specify passwords, TLS/SSL, persist data across sessions, connect to databases, specify ontologies, and more. 

* For a list of many investigation-oriented options, see their [settings reference page](configure-investigation).

* See [update, backup, & migration instructions](../tools/update-backup-migrate.md) for preserving configurations and  data across installations.

* For advanced Python notebook and application configuration, see [PyGraphistry configuration](configure-pygraphistry.md).

## Add your team and provide API keys

See [user creation docs](../tools/user-creation.md)


## Configuration places

### Primary: data/config/custom.env

* Graphistry is primarily configured by setting values in `data/config/custom.env`
* Connector, ontology, and pivot configuration is optionally via `data/pivot-db/config/config.json`. Many relevant options are [detailed in a reference page](configure-investigation.md).

Between edits, restart one or all Graphistry services: `./graphistry stop`  and `./graphistry up -d`.

We typically recommend doing targeted and localized restarts via `./graphistry stop service1 service2 ...` and `./graphistry up -d --force-recreate --no-deps service1 service2 ...`. Contact staff for guidance.


### Secondary:: docker-compose.yml, Caddyfile, `pivot-db/`

* More advanced administrators may edit `docker-compose.yml` .  Maintenance is easier if you never edit it.
* Custom TLS is via editing `Caddyfile`([Caddy docs](https://caddyserver.com/docs/automatic-https)), see below
* Visual playbooks may be configured via `data/pivot-db/config/config.json`

## SSO

Contact staff for setting up internal SSO (OIDC: Okta, ...) or via social logins to GitHub/Google

If using an external proxy or load balancer, configure Graphistry's site domain setting (see above) and check above TLS settings

Recommendations for SSO when self-hosting:
* Setup email
* Mark SSO as site-wide
* Disallow non-SSO account creation
* Decide whether SSO users can automatically join organizations without an invitation

## TLS

We encourage everyone to use HTTPS over HTTP, especially through the automatic TLS option, for [securing authentication](../security/authentication.md)

Graphistry supports both free automatic TLS within your server (Caddy/LetsEncrypt) and offloading to an external load balancer or proxy

As part of TLS configuration, decide whether to allow cross-origin embedding of private visualizations

### TLS Hardening

#### Caddy

If Caddy is used for TLS, several additional policies may be of interest, but only use ones that match your intended usage patterns:

```
grphstry.my-website.org, :80 {
  ...
  @mismatchedHost {
        not host grphstry.my-website.org localhost
  }
  handle @mismatchedHost {
        respond 400
  }
  ...
  reverse_proxy nginx:80 {
        # enable HSTS (1yr)
        header_down Strict-Transport-Security max-age=31536000;

        # disable clients from sniffing the media type
        header_down X-Content-Type-Options nosniff

        # clickjacking protection
        header_down X-Frame-Options SAMEORIGIN

        # keep referrer data off of HTTP connections
        header_down Referrer-Policy no-referrer-when-downgrade
  }
}
```

Note: Configuration line `header_down X-Frame-Options SAMEORIGIN` will prevent all cross-origin embedding. By default, public content can be cross-origin embedded while private content cannot. See also `COOKIE_SAMESITE` for enabling authorized private content in cross-origin embeddings.

#### Application servers

Also inform the Graphistry application servers to use secure cookies in `data/config/custom.env`:

```bash
COOKIE_SECURE=true
```

For visualizations to be embeddable in different origin sites, enable `COOKIE_SECURE` and then disable `COOKIE_SAMESITE`:

```bash
COOKIE_SAMESITE=None
```

... then restart: `./graphistry up -d --force-recreate --no-deps nexus`


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

The above step may fail if your server does not allow outbound internet traffic. To work around, perform a [manual LetsEncrypt Certbot handshake for Caddy](../security/configure-tls-caddy-manual-lets-encrypt-handshake.md).

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



To safelist typical internal IPs `192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 127.0.0.1/8 fd00::/8 ::1`:

```
reverse_proxy nginx:80 {
	trusted_proxies private_ranges
}
```

If you know the specific range, you can provide that as well:

```
reverse_proxy nginx:80 {
	trusted_proxies 173.245.48.0/20 103.21.244.0/22
}
```


### Debugging TLS

Custom TLS setups often fail due to the certificate, OS, network, Caddy config, and file permissions. To perform isolated checks on each, try:

* Test the certificate
* Test a [standalone Caddy static file server](https://www.baty.net/2018/using-caddy-for-serving-static-content/)
* ... Including on another box, if OS/network issues are suspected
* Check the logs of `./graphistry logs -f -t caddy nginx`
* Test whether the containers are up and ports match via `./graphistry ps`, `curl`, and `curl` from within a docker container (so within the docker network namespace)

If problems persist, please reach out to your Graphistry counterparts. Additional workarounds are possible.


## Email

*Optional*

See the [email](email.md) section

## Python, PyGraphistry, & GFQL

You may find it useful to customize specific endpoints:

* [PyGraphistry](configure-pygraphistry.md) for how notebooks talk to your Graphistry instance
* [Python endpoint](configure-python.md) for how users can run arbitrary Python code against Graphistry datasets and leverage the server GPU
* GFQL Endpoint for how users can run queries against Graphistry datasets using GFQL: No configuration at this time

## Site domain

*Optional*

In the Admin portal, go to Sites and change the `Domain name` to your domain, such as `graphs.acme-corp.com` 

This aids scenarios such as when using an outside proxy and ensuring that web users see the intended external domain instead of the internal one leaking through


## GPU Configuration

For multi-GPU setups and GPU memory management, Graphistry provides several configuration options:

* **GPU Memory Watcher**: Monitor GPU memory and automatically terminate runaway processes before OOM errors
* **Per-Service GPU Assignment**: Assign specific GPUs to specific services for workload isolation
* **Multi-Worker Configuration**: Configure worker counts to match your GPU configuration

### Quick Setup

Auto-configure optimal GPU settings using the GPU configuration wizard:

```bash
# Interactive mode
./etc/scripts/gpu-config-wizard.sh

# Export to custom.env
./etc/scripts/gpu-config-wizard.sh -E ./data/config/custom.env

# Use hardware preset (140+ available)
./etc/scripts/gpu-config-wizard.sh -p aws-p3-8xlarge
```

See [GPU Configuration Wizard](../tools/gpu-config-wizard.md) for the full preset list and usage details.

For detailed GPU configuration options, see [Performance Tuning - Multi-GPU](../debugging/performance-tuning.md#multi-gpu-tuning).

## Performance

See [performance tuning](../debugging/performance-tuning.md)


## Reverse proxy

### Built-in proxying

Graphistry routes all public traffic through Docker container Caddy (or Caddy pod in Kubernetes), so you generally modify settings in `data/config/custom.env`, `docker-compose.yml`, or Caddy settings in `data/config/Caddyfile`. Further internal proxying may occur, but we do not advise manipulating internal tiers.

### External proxies

You may externally redirect traffic, such as through an AWS Load Balancer or CloudFlare

* See above TLS discussion
* Set the Site  


### Change public port

If `80` / `443` are already taken, such as when running multiple Graphistry instances on the same box, you may want to change to another port. For example, to expose public port `8888` for Graphistry's HTTP traffic instead of `80`, set in `data/config/custom.env`:

```bash
CADDY_HTTP_PORT=8888
```

Or alternatively configure `docker-compose.yml` to map it as follows:

```yaml
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


## Streamlit Dashboards

Separately [configure the public and private Streamlit dashboards](configure-dashboards.md)


## Visual Playbooks

**Note:** We strongly recommend new users contact the Graphistry team about early access to Louie before starting new usage of the Visual Playbook environment.


### Connectors

Optionally, you can configure Graphistry to use database connectors. Graphistry will orchestrate cross-database query generation, pushing them down through the database API, and returning the combined results to the user. This means Graphistry can reuse your existing scaleout infrastructure and make its data more accessible to your users without requiring a second copy to be maintained. Some connectors further support use of the [Graphistry data bridge](../tools/bridge.md) for proxying requests between a Graphistry cloud server and an intermediate on-prem data bridge instead of directly connecting to on-prem API servers.

#### Security Notes 

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

`./graphistry stop && ./graphistry up -d` or `./graphistry stop nginx pivot && ./graphistry up -d`

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

4. Restart the pivot service (see Get Started) and test the connector as per above. You can test the underlying Splunk API configuration by running `curl -u admin:changme  https://splunk.host.name.here:8089/services/search/jobs/export  -d search="search * | head 3" -d output_mode=csv` from your local Splunk server and your Graphistry server.

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


2. Restart the pivot service (see Get Started) and test the connector as per above. In-tool, you can test the connection status for the connector panel by clicking the 'check status' button for the Neo4j connector. If there is an error, you can further test your Neo4j database network connectivity by trying a Graphistry Jupyter notebook demo for Neo4j to connect to Neo4j from the notebook.


### Data bridge

In scenarios such as a Graphistry cloud server accessing on-prem API servers, an intermediate on-prem data bridge may be necessary. You can mix bridged and direct (default) connectors in the same Graphistry server. Learn more about the [Graphistry data bridge](../tools/bridge.md).

### Variants

* Give your Graphistry implementation user increased permissions so they can embed Graphistry into existing dashbboard and notification systems, such as for embedded visualizations and quicklinks into contextual [investigation templates](templates.md)* Run a [Graphistry data bridge](../tools/bridge.md), if available for your connector, which may help with cases such as firewalls preventing incoming connections from Graphistry to your database
* Run a bastion server between Graphistry and your database, such as a new Splunk search head
* Create fine-grained permissions by running multiple Graphistry virtual servers, with a new Splunk role per instance

### Ontology

See [custom ontology extensions](configure-ontology.md) and [settings reference page](configure-investigation.md) for full options. Topics include controlling:

* Map Column -> Type
* Map Type -> color, icon, size
* Map node/edge titles

### Pivots

Every connector comes with a base set of pivots. See [custom pivots](configure-custom-pivots.md) for teaching Graphistry new pivots based on existing connectors and pivots.
