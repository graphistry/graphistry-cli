# Manual Caddy LetsEncrypt TLS Certificates

The following instructions show how to do a manual LetsEncrypt handshake for Caddy, including for internal IPs. 

It helps work around challenges getting a TLS certificate in some enterprise environment. This is common due to internal security team processes, and further complicated by firewall policies preventing outbound communications needed for LetsEncrypt's automatic TLS certificate generation protocol's handshake.

The instructions can be used in two ways:

* Graphistry staff can assist with TLS setup, including a temporary Graphistry-owned DNS entry such as `https://<my-org>.graphistry.com`.
* The same instructions can be used with DNS entries you control


## Steps

### 1. Generate Certbot certificates for LetsEncrypt

*Skip if Graphistry staff is handling for you*

On your home machine or any other with internet access and Python, such as a container:

* `sudo pip install certbot`
* `sudo pip install cryptography --upgrade`
* `sudo certbot certonly --manual --preferred-challenges dns --server https://acme-v02.api.letsencrypt.org/directory --manual-public-ip-logging-ok -d '<domain>'`

Domain is an entry like `'my-org.graphistry.com'` -- not `https://` needed

### 2. Manual DNS handshake

*Skip if Graphistry staff is handling for you*

* Add the TXT challenge (key+value) to the DNS records for your domain

* Save the keys emitted on the machine from Step 1 when LE successfully verifies the TXT record

### 3. Add the TLS certificates to your Graphistry server's Caddy service

In your Graphistry server:

* Copy `privkey.pem`, `fullchain.pem` to `${GRAPHISTRY_HOME}/data/caddy/config/`

* Edit `${GRAPHISTRY_HOME}/data/config/Caddyfile`:

```
my-org.graphistry.com {
  tls /config/fullchain.pem /config/privkey.pem
  respond /caddy/health/ 200 {
      body "{\"success\": true}"
      close
  }
  reverse_proxy nginx:80
}
```

Optionally, there are additional [Caddyfile http/https header settings](https://github.com/graphistry/graphistry-cli/blob/master/docs/configure.md#tls-hardening)

### 4. Restart Caddy

From `${GRAPHISTRY_HOME}`, run:

* `docker compose up -d --force-recreate --no-deps caddy`
* Watch logs with `docker compose logs -f -t --tail=1 caddy`

### 5. Renewing certs
* follow steps 1-4 above 
* `docker compose stop caddy` & remove caddy generate files in data/caddy/{data,config}/*
* `docker compose up -d --force-recreate --no-deps caddy`
