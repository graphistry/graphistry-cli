# Configuring Graphistry

Administrators can specify passwords, TLS/SSL, persist data across sessions, connect to databases, specify ontologies, and more. 

## Four configurations: .env, docker-compose.yml, pivot.json, and etc/ssl/*

* Graphistry is configured through a `.env` file, which is what you primarily edit
* It can be used to enable a `data/pivot.json`, which supports the same commands, but is more convenient for heavier configurations such as json ontologies
* The `docker-compose.yml` reads the `.env` file, and more advanced administrators may edit the yml file as well. Maintenance is easier if you never edit it.
* TLS is via `etc/ssl/*`

## Backup your configuration

Graphistry tarballs contain default `.env` and `docker-compose.yml`, so make sure you put them in safe places. 

If you create `json` config files, such as a `data/config/pivot.json`, back them up too.

If you configure `TLS`, backup `etc/ssl`.

## Persist user data across restarts

We recommend persisting data to `${PWD}/data/config/{pivot.json,viz.json}` and `${PWD}/data/investigatigations,viz}`, or the same on a network mount, and running regular backups.

Configure your `.env` and `docker-compose.yml` as follows:

**data/config/{pivot,viz}.json**

Create `data/config/pivot.json` and `data/config/viz.json` with the value `{}`:

`mkdir -p data/config && echo "{}" > data/config/pivot.json && echo "{}" > data/config/viz.json`

**.env**

Eanble in `.env`:

```
GRAPHISTRY_CONFIG=./data/config
GRAPHISTRY_INVESTIGATIONS=./data/investigations
GRAPHISTRY_VIZ=./data/viz
PIVOT_CONFIG_FILES=/opt/graphistry/config/pivot.json
VIZ_CONFIG_FILES=/opt/graphistry/config/viz.json
GRAPHISTRY_INVESTIGATIONS_CONTAINER_DIR=/opt/graphistry/apps/core/pivot/data
GRAPHISTRY_VIZ_CONTAINER_DIR=/tmp/graphistry
```

These will enable reading of `data/config/{pivot,viz}.json` and write user data to `data/{investigations,viz}`.

**docker-compose.yml**

Enable in `docker-compose.yml` if not already there:

```
viz:
    ...
    volumes:
      - ${GRAPHISTRY_VIZ}:${GRAPHISTRY_VIZ_CONTAINER_DIR}
```
and
```
pivot:
    ...
    volumes:
       - ${GRAPHISTRY_CONFIG}:/opt/graphistry/config
       - ${GRAPHISTRY_INVESTIGATIONS}:${GRAPHISTRY_INVESTIGATIONS_CONTAINER_DIR}
```    


## Connectors

Uncomment and edit lines of `.env` corresponding to your connector and restart Graphistry:

```
ES_HOST...
SPLUNK...
```

Finer-grained configurations are easier to setup and maintain via `data/config/pivot.json`. 

Your Graphistry support engineer can provide examples.


## Passwords

Graphistry passwords are random across container runs so you likely want to override and keep.

Uncomment and edit lines of `.env` for `PIVOT_PASSWORD_HASH` (see instructions in `.env`) for the password used on  `your-site.com/pivot`

Your API keys should be stable across runs. If not, contact your Graphistry support engineer.

## Ontology

Setup Graphistry for data persistence (see above), and then in `data/config/pivot.json`, add and configure the below.

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


Nginx Config and SSL
--------------------

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
