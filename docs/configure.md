# Configuring Graphistry

Administrators can specify passwords, TLS/SSL, persist data across sessions, connect to databases, specify ontologies, and more. 

For a list of many investigation-oriented options, see their [settings reference page](configure-investigation.md).

## Top configuration places: .env, .pivot-db/config/config.json

* Graphistry is primarily configured through a `.env` file
* Richer ontology configuration is optionally via `.pivot-db/config/config.json`. Many relevant options are [detailed in a reference page](configure-investigation.md).

Between edits, restart one or all Graphistry services: `docker-compose stop`  and `docker-compose up -d`


## Further configuration: docker-compose.yml, Caddyfile, and etc/ssl/*

* More advanced administrators may edit `docker-compose.yml` .  Maintenance is easier if you never edit it.
* Custom TLS is via editing `Caddyfile`([Caddy docs](https://caddyserver.com/docs/automatic-https)) and mounting your certificates via `docker-compose.yml` ([Caddy Docker docs](https://github.com/abiosoft/caddy-docker)). Caddy supports LetsEncrypt with automatic renewal, custom certificates and authorities, and self-signed certificates. Deprecated, you can also modify Nginx config (`etc/ssl/*`)

## Backup your configuration

* Graphistry tarballs contain default `.env` and `.pivot-db/config/config.json`, so make sure you put them in safe places and back them up if edited

* TLS: If you configure `TLS`, backup `Caddyfile` (and likely `.caddy`) or if you use Nginx, `etc/ssl`. 

* If you edit `docker-compose.yml` (not encouraged), back that up too.

## Backup your data

* Graphistry: `/home/ubuntu/graphistry/data` (viz data and workbooks) and `.pivot-db` (investigations, pivots, templates, and json config)

* Jupyter Notebooks: By default, notebooks are kept inside the Jupyter container. For a host-accessible access notebook folder, create `${PWD}/.notebooks` and mount it in `docker-compose.yml`:
```
  notebook:
    volumes:
      - ${PWD}/.notebooks:/home/graphistry/notebooks
```
New host-accessible folder will appear as a top-level folder `notebooks` in Jupyter upon restart. Include `${PWD}/.notebooks/` in your backups going fowards.

## Backup your users

By default, Graphistry currently requires manual `pgdump` and import of the `postgres` volumes. 

To replicate the simpler future process of simply backing up `.postgres/`:

1. Create user data folders;

```
mkdir -p .postgres/data
mkdir -p .postgres/backups
```

2.  Modify `docker-compose.yml`:

```
  postgres:
   ...
    volumes:
    - .postgres/data:/var/lib/postgresql/data
    - .postgres/backup
```

3. Going forward, simply backup `.postgres/`



## Connectors

Uncomment and edit lines of `.env` corresponding to your connector and restart Graphistry:

```
ES_HOST...
SPLUNK...
```


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
