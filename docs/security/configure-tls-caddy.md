# Configure TLS with Caddy

Graphistry's web traffic enters through the built-in [Caddy](https://caddyserver.com/docs/) reverse proxy (service `caddy`), which terminates TLS and forwards to Graphistry's internal `nginx`. This page covers the ways to give Caddy a certificate, redirecting plain HTTP, security headers, offloading TLS to your own load balancer, and debugging.

We encourage everyone to use HTTPS, which is required for [securing authentication](authentication.md). After enabling TLS, also set the [secure cookie options](../app-config/configure.md#tls) for the application servers.

## Choose an option

| Option | Use when | Renewal |
| --- | --- | --- |
| [Automatic TLS](#automatic-tls-let-s-encrypt) | The server has a public DNS name and Let's Encrypt can reach it on port 80 or 443 | Automatic |
| [Custom certificates](#custom-certificates) | Your organization issues certificates (internal CA, purchased certificate), or the server has no internet access | Manual: replace the files and restart Caddy |
| [Manual Let's Encrypt handshake](configure-tls-caddy-manual-lets-encrypt-handshake.md) | You want a Let's Encrypt certificate but inbound validation is blocked | Manual: repeat the handshake |
| [Offload TLS](#offload-tls-to-a-load-balancer-or-proxy) | A load balancer or proxy in front of Graphistry already handles TLS | At the load balancer |

## How Caddy is configured

* Configuration file: `data/config/Caddyfile` in your Graphistry folder (seen by the container as `/etc/caddy/Caddyfile`)
* Caddy's other folders, as seen by the container:
  * `data/caddy/config/` is `/config`: put custom certificate files here
  * `data/caddy/data/` is `/data`: certificates and keys Caddy obtains itself
* Check a change before applying it:

```bash
./graphistry exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
```

* Apply a change by restarting only Caddy, from your Graphistry folder:

```bash
./graphistry up -d --force-recreate --no-deps caddy
./graphistry logs -f -t --tail=100 caddy
```

Use the `./graphistry` wrapper rather than plain `docker compose`: the wrapper sets the Docker Compose project name used by the running stack. Plain `docker compose` run in the release folder uses a different project name and tries to start a second Caddy, which fails with `Bind for 0.0.0.0:80 failed: port is already allocated`.

## Automatic TLS (Let's Encrypt)

Caddy obtains and renews a free [Let's Encrypt](https://letsencrypt.org/) certificate for any site address that is a domain name. Requirements:

* A DNS name, such as `graphistry.website.org`, whose A record points at the server's public IP
* Let's Encrypt's validation servers can reach the server on port 80 (HTTP-01 challenge) or 443 (TLS-ALPN-01 challenge) from the internet
* The server can make outbound HTTPS connections to Let's Encrypt

Sample `Caddyfile`, replacing `graphistry.website.org` with your server's domain:

```
graphistry.website.org {
  respond /caddy/health/ 200 {
    body "{\"success\": true}"
    close
  }
  reverse_proxy nginx:80
}
```

Restart Caddy and watch its logs for `certificate obtained successfully`.

Wildcard names such as `*.website.org` cannot use this flow: Let's Encrypt only issues wildcard certificates through a DNS challenge, which requires a Caddy build with your DNS provider's plugin.

### Firewalls that restrict inbound traffic

If inbound ports are limited to known addresses, such as a cloud security group that only allows your office or VPN, Let's Encrypt cannot validate the server. The Caddy logs then show `challenge failed` with `Timeout during connect (likely firewall problem)`, and Caddy keeps retrying. After repeated failures it retries against the Let's Encrypt staging environment, whose certificates browsers do not trust.

Options:

* Allow port 80 from anywhere temporarily, restart Caddy, wait for `certificate obtained successfully` (usually within a minute), then remove the rule. Let's Encrypt certificates last 90 days and Caddy renews them about 30 days before expiry, so renewal needs port 80 reachable again at that point. Plan for it, or choose one of the options below.
* Use [custom certificates](#custom-certificates)
* Use the [manual Let's Encrypt handshake](configure-tls-caddy-manual-lets-encrypt-handshake.md)

If the server's public IP changes (for example, a cloud instance without a static or elastic IP is stopped and started), update the DNS record before Caddy next needs to validate.

## Custom certificates

If you already have certificates, such as from your organization's certificate authority, Caddy can use them instead of Let's Encrypt:

* Use PEM files: the certificate as a full chain (server certificate followed by intermediates) and an unencrypted private key. Caddy cannot prompt for a key passphrase.
* The certificate's Subject Alternative Names must include the domain users browse to. Browsers ignore the Common Name.
* Copy the files into `data/caddy/config/` in your Graphistry folder. The `caddy` container sees that folder as `/config`:

```bash
cp fullchain.pem privkey.pem data/caddy/config/
chmod 600 data/caddy/config/privkey.pem
```

* Modify `data/config/Caddyfile`:

```
your.site.ngo {
  tls /config/fullchain.pem /config/privkey.pem
  respond /caddy/health/ 200 {
    body "{\"success\": true}"
    close
  }
  reverse_proxy nginx:80
}
```

* Restart Caddy: `./graphistry up -d --force-recreate --no-deps caddy`

Note the use of a fully qualified domain name in the first line, and that the file paths are for the `caddy` container's file system, not the host file system. Older documentation used `./.caddy` and `/root/.caddy` paths, which current releases do not mount.

With a `tls` line naming certificate files, Caddy does not contact Let's Encrypt for that domain, so this works without outbound internet access. On networks where the certificate authority's OCSP responder is unreachable, Caddy may log OCSP stapling warnings; to stop it trying, add a global options block at the top of the Caddyfile:

```
{
  ocsp_stapling off
}
```

Caddy does not renew certificates it is given: replace the files and restart Caddy before they expire.

## Redirect HTTP to HTTPS

For a site address that is a domain name, Caddy automatically redirects `http://` requests for that name to `https://`.

Avoid listing `:80` in the same site address, as in `your.site.ngo, :80 {`. That serves the full application over plain HTTP to any request that does not match the domain name, such as browsing by IP address, and browsers show "Not secure". Instead, add a separate `:80` block that keeps the health check and redirects everything else:

```
:80 {
  handle /caddy/health/ {
    respond 200 {
      body "{\"success\": true}"
      close
    }
  }
  handle {
    redir https://your.site.ngo{uri} permanent
  }
}
```

Keep `/caddy/health/` answering on port 80: the `caddy` container's Docker health check calls `http://localhost/caddy/health/`.

## Security headers

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

The `@mismatchedHost` rule rejects requests for any other host name, including requests by IP address, so this example can list `:80` without serving the application over plain HTTP by IP.

Note: Configuration line `header_down X-Frame-Options SAMEORIGIN` will prevent all cross-origin embedding. By default, public content can be cross-origin embedded while private content cannot. See also `COOKIE_SAMESITE` in the [application server settings](../app-config/configure.md#tls) for enabling authorized private content in cross-origin embeddings.

## Offload TLS to a load balancer or proxy

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

## Debugging TLS

Custom TLS setups often fail due to the certificate, OS, network, Caddy config, and file permissions. To perform isolated checks on each, try:

* Validate the Caddyfile (see [How Caddy is configured](#how-caddy-is-configured))
* Check the logs of `./graphistry logs -f -t caddy nginx`
* Check which certificate the server presents:

```bash
openssl s_client -connect localhost:443 -servername your.site.ngo </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -enddate
```

* Test whether the containers are up and ports match via `./graphistry ps`, `curl`, and `curl` from within a docker container (so within the docker network namespace)
* Test a [standalone Caddy static file server](https://www.baty.net/2018/using-caddy-for-serving-static-content/), including on another box if OS/network issues are suspected

Common symptoms:

* `challenge failed` with `Timeout during connect (likely firewall problem)`: Let's Encrypt cannot reach the server, see [Firewalls that restrict inbound traffic](#firewalls-that-restrict-inbound-traffic)
* `no such file or directory` for a certificate: the `tls` paths must be container paths under `/config`, see [Custom certificates](#custom-certificates)
* "Not secure" when browsing by IP address: see [Redirect HTTP to HTTPS](#redirect-http-to-https)
* "Not secure" on some machines only: the certificate file is missing intermediates, or those machines do not trust your certificate authority
* The browser still shows an old certificate after a change: close all of its windows, or test in a private window

If problems persist, please reach out to your Graphistry counterparts. Additional workarounds are possible.
