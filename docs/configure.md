# Configuring Graphistry

Administrators can add users, specify passwords, TLS/SSL, persist data across sessions, connect to databases, specify ontologies, and more. 

* For a list of many investigation-oriented options, see their [settings reference page](configure-investigation.md).

* See [update, backup, & migration instructions](update-backup-migrate.md) for preserving configurations and  data across installations.

## Add your team and provide API keys

See [user creation docs](user-creation.md)


## Top configuration places: .env, .pivot-db/config/config.json

* Graphistry is primarily configured through a `.env` file
* Richer ontology configuration is optionally via `.pivot-db/config/config.json`. Many relevant options are [detailed in a reference page](configure-investigation.md).

Between edits, restart one or all Graphistry services: `docker-compose stop`  and `docker-compose up -d`


## Further configuration: docker-compose.yml, Caddyfile, and etc/ssl/*

* More advanced administrators may edit `docker-compose.yml` .  Maintenance is easier if you never edit it.
* Custom TLS is via editing `Caddyfile`([Caddy docs](https://caddyserver.com/docs/automatic-https)) and mounting your certificates via `docker-compose.yml` ([Caddy Docker docs](https://github.com/abiosoft/caddy-docker)). Caddy supports LetsEncrypt with automatic renewal, custom certificates and authorities, and self-signed certificates. Deprecated, you can also modify Nginx config (`etc/ssl/*`)


## Connectors

Optionally, you can configure Graphistry to use database connectors. Graphistry will orchestrate cross-database query generation, pushing them down through the database API, and returning the combined results to the user. This means Graphistry can reuse your existing scaleout infrastructure and make its data more accessible to your users without requiring a second copy to be maintained. 


### Security Notes 

* Graphistry only needs `read only` access to the database
* Only one system-wide connector can be used per database per Graphistry virtual server at this time. Ex: You can have Splunk user 1 + Neo4j user 2 on one running Graphistry container, and Splunk user 3 + Neo4j user 2 on another running Graphistry container.
* [Templates](templates.md) and other embedding modes do not require further Graphistry configuration be beyond potentially API key generation. However, Graphistry implementors will still need access to external dashboards, APIs, etc., into which they'll be embedding Graphistry views.

### Get started

1. Uncomment and edit lines of `.env` corresponding to your connector and restart Graphistry:

```
ES_HOST...
SPLUNK...
```

2. Restart `graphistry`, or at least the `pivot` service:

`docker-compose restart` or `docker-compose restart pivot`

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

3. Configure Graphistry's `.env` with the Splunk server and user information:

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

4. Restart and test the connector as per above

5. Variants

* Give your Graphistry implementation user increased permissions so they can embed Graphistry into existing dashbboard and notification systems, such as for embedded visualizations and quicklinks into contextual [investigation templates](templates.md)* Run a (Graphistry data bridge)[bridge.md], if available for your connector, which may help with cases such as firewalls preventing incoming connections from Graphistry to your database
* Run a bastion server between Graphistry and your database, such as a new Splunk search head
* Create fine-grained permissions by running multiple Graphistry virtual servers, with a new Splunk role per instance


## Ontology

See [settings reference page](configure-investigation.md) for full options.

Edit `.pivot-db/config/config.json` via the below and restart Graphistry:

* Icons: Use Font Awesome 4 names ( https://fontawesome.com/v4.7.0/icons/ )
* Colors: Use hex codes (`#vvvvvv`). To find hex values for different colors, you can use Graphistry's in-tool background color picker.

```
{
    "ontology": {
        "products": {
            "myOntologyName": {
                "colTypes": {
                    "src_ip": "ip",
                    "dest_ip": "ip",
                    "myEventColumnName": "myTypeTag"
                }
            }
        },
        "icons": {
            "ip": "laptop",
            "myTypeTag": "fighter-jet"
        },
        "sizes": {
            "ip": 800,
            "myTypeTag": 100
        },
        "colors": {
            "ip": "#FF0000",
            "myTypeTag": "#000000"
        }
    }
}
```


TLS: Caddyfile and Nginx Config
--------------------

To simplify credentials deployment, Graphistry is moving from Nginx to Caddy:

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

### Nginx (DEPRECATED)

There are two helper ssl configs provided for you in the `./etc/nginx` folder.

**ssl.self-provided.conf**

```
listen 443 ssl;
# certs sent to the client in SERVER HELLO are concatenated in ssl_certificate
# Includes the website cert, and the CA intermediate cert, in that order
ssl_certificate            /etc/ssl/ssl.crt;

# Unencrypted key file
ssl_certificate_key        /etc/ssl/ssl.key;
```

Notice the location and file names of the SSL keys and certs. Also the SSL include in the supplied `graphistry.conf`.

**graphistry.conf**

```
...
    
    server_name                 _;

    proxy_http_version          1.1;
    client_max_body_size        256M;

    import /etc/nginx/graphistry/ssl.conf

    proxy_set_header            Host              $http_host;
    proxy_set_header            X-Real-IP         $remote_addr;
    proxy_set_header            X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header            X-Forwarded-Proto $scheme;

    # Support proxying WebSocket connections
    proxy_set_header            Upgrade           $http_upgrade;
    proxy_set_header            Connection        $connection_upgrade;

    # Block Slack's link preview generator bot, so that posting a viz link into Slack doesn't
    # overwhelm the server. We should have a more robust system for stopping all bots, though
    if ($http_user_agent ~* Slack) {
        return 403;
    }

...

```

If you uncomment the nginx volume mounts in the `docker-compose.yml` and supply SSL key and certs, SSL will start 
right up for you.

**docker-compose.yml**

```

  nginx:
    ports:
      - 80:80
      - 443:443
    links:
      - pivot
      - central
    # volumes:  
    #   - ./etc/nginx/nginx.conf:/etc/nginx/nginx.conf
    #   - ./etc/nginx/graphistry.conf:/etc/nginx/conf.d/graphistry.conf
    #   - ./etc/nginx/ssl.self-provided.conf:/etc/nginx/graphistry/ssl.conf
    #   - ./etc/ssl:/etc/ssl

```

There is an alternate SSL conf you can use if yo uare not using a self signed cert. `./etc/nginx/ssl.conf`.

We have a helper tool for generating self signed ssl certs that you can use by running:

`bash scripts/generate-ssl-certs.sh`
