# Configuring Graphistry

Administrators can specify passwords, TLS/SSL, persist data across sessions, connect to databases, specify ontologies, and more. 

For a list of many investigation-oriented options, see their [settings reference page](configure-investigation.md).

## Four configurations: .env, docker-compose.yml, pivot.json, and etc/ssl/*

* Graphistry is configured through a `.env` file, which is what you primarily edit
* It can be used to enable a `.pivot-db/config/config.json`, which supports the same commands, but is more convenient for heavier configurations such as json ontologies
* The `docker-compose.yml` reads the `.env` file, and more advanced administrators may edit the yml file as well. Maintenance is easier if you never edit it.
* TLS is via editing `Caddyfile`([docs](https://caddyserver.com/docs/automatic-https), or being phased out, Nginx config (`etc/ssl/*`)
* Many of the `.env` and `docker-compose.yml` options are [detailed in a reference page](configure-investigation.md).

## Backup your configuration

Graphistry tarballs contain default `.env` and `.pivot-db/config/config.json`, so make sure you put them in safe places and back them up.

If you configure `TLS`, backup `Caddyfile` or `etc/ssl`. 

If you edit `docker-compose.yml` (not encouraged), back that up too.

## Backup your data

See `/home/ubuntu/graphistry/data` (default in `docker-compose.yml`), `.pivot-db/investigations`, and `.pivot-db/pivots`


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

For automatic TLS (Let's Encrypt) and manual certs, [see official docs](https://caddyserver.com/docs/tls)

### Nginx

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
    image: spengler.grph.xyz/release/nginx-proxy:2000
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
