# Security Hardening

Graphistry instances come with security out-of-the-box, and are typically further secured by system administrators or Graphistry staff and through appropriate use. Different configurations make sense based on deployment environment, intended use cases, and threat model.

Read on for:

* Out-of-the-box config (Admin)
* Server configuration (Admin)
* Recommended network config (Admin)
* Connector configuration (Admin)
* Safely using Graphistry APIs (Developer)
* Air gapping
* Sensitive data

For futher information, see:

* [Overall system configuration](configure.md)
* [Security threat model](threatmodel.md)
* [Authentication](authentication.md)
* [Deployment planning](deployment-planning.md)
* [Capacity planning](../hardware-software.md)


## Out-of-the-box config

* First user to create an account is the web Admin
  * Cloud-specific deployments may tailor secure initialization, such as AWS defaulting to `admin` / `i-instanceID`
* Web Admins then create other users and with differing role levels: Admin, User, Inactive
  * As a web Admin, we recommend also creating a non-admin account for yourself
* Sessions are protected with JWT tokens and HTTP-only CSRF tokens
  * TLS recommended
* Visualizations are shared as web keys

## Server configuration

Self-hosting a server requires managing your own server security, such as periodic updates.

If using a Cloud Marketplace distribution, you can always update to latest recommended system settings by updating to a latest Graphsitry-provided version.

One common security recommendation is to seperate per-user lower-privilege server admin accounts instead of a shared root. These users will require access to the Docker daemon and `$GRAPHISTRY_HOME` (likely `/var/graphistry` or `~/graphistry`). We note that most web admins do not require server access.

### Session configuration

You may want to tweak session security options in `data/config/custom.env` (see defaults in `.env`):

```bash
# APIS
JWT_ALLOW_REFRESH=True
JWT_REFRESH_EXPIRATION_DELTA=86400
#Force re-token every hour
JWT_EXPIRATION_DELTA=3600

# WEB
# Web session cookie timeout default 2 weeks
SESSION_COOKIE_AGE=1209600
```

Upon changing, restart the web server with the fresh environment: `docker-compose up -d --force-recreate --no-deps nexus`


## Recommended network config: TLS, IPs, Ports

### TLS Certificates

We **highly** encourage using TLS and make it easy:

* [Configure the Caddyfile](configure.md) for auto-TLS with one line (recommended), add your own TLS certificate, or offload TLS
* TLS is required for JWT auth to be secured against MitM attacks
* The built-in auto-TLS requires a domain name

### Firewalls & SSH

We recommend secure use of SSH and to consider using a firewall for VPN-only traffic. (Graphistry runs fine air-gapped as well.) If you do not have access to a firewall but want IP filtering, contact Graphistry staff for alternatives.

The below should be standard for cloud and enterprise environments:

* SSH: Keys for admins
* DNS: Assign a domain name and set it in the Graphistry Admin Portal's Site Settings
* Server firewall - Inbound recommendations:
  * VPN-only if publishing is not meant for the general web
  * If an external load balancer and bastion are available, VPC-only
  * HTTP->HTTPS auto-upgrade either via the built-in Caddy proxy, or when TLS-offloading, at the external system
  * Port 22 (ssh): Always on, or manually enabled during administration
  * Port 443 (https): Always on, unless offloading TLS
  * Port 80 (http): Always on, or manually enabled during administration
  * If the GPU/CPU is reused for other applications, whatever ports those systems need (we like to preassign a limited safe range)
* Server firewall - Outbound port recommendations:
  * VPN user browsers (if no general web publishing)
  * Whatever database and API systems (servers and cloud regions)

Graphistry can work with TLS offloading (CF, AWS ALBs, ...) or handle internally (Caddy)

# Connector configuration

Connectors are used by the (currently) admin-level investigator tool. Security configuration is generally relevant for enabling it to work with outside systems, and to restrict what users can do.

[See the main connector docs](configure.md) for more information.

### Connector firewall settings
* If Graphistry is connecting to a database or API such as Splunk or Neo4j, ensure that system allows incoming/outgoing connections from Graphistry
* Some systems have hard-to-work-with firewalls and may benefit from using a [Graphistry data bridge](bridge.md) to limit database communications to outbound-only HTTP/HTTPS.

### Restricting connectors

Check if your database or API supports restricted roles. For example, when Graphistry is connected to Splunk, you may want to create a Splunk API user that only has read access to a few indexes, and configure Graphistry to use that account.

# Safely using Graphistry APIs


* Safe defaults
  * Ensure TLS is configured (Caddy or offloaded)
  * Prefer the 2.0 API over the 1.0 where available
* Principle of least privilege: API tokens act on behalf of the owning account, so be as minimal as needed
  * Prefer User accounts over Admin accounts
  * Prefer individual accounts over shared accounts
  * See the API docs for more on delegation scenarios such as for revocing satellite system capabilities
* Pay attention to data movement to improve performance and limit attack opportunities:
  * Prefer server<>server APIs for data uploads
  * Prefer client<>client APIs for user interactions

# Air gapping

Some environments require operation without access to the public internet

* Graphistry works out-of-the-box without public internet access
* Your browser must be able to connect to your Graphistry server, and if using data connectors, your Graphistry server must be able to connect to your data sources
* Optional, enable the explicit air gap mode
  * Effect: This disables optional components like our support integration use the public internet
  * Benefit: Increase privacy, and potentially avoid usage slowdowns from waiting on non-responsive requests
  * Method 1: Before first system start, in your `data/config/custom.env`, set `AIR_GAPPED=1`
  * Method 2: User -> Admin portal -> Settings -> Config -> Check IS_AIR_GAPPED and save


# Sensitive data

As a Docker-based Linux system, most custom data is stored in Docker volumes. The remaining data, such as server accounts, are in standard Linux locations.

In Graphistry, persistent data appears as the Postgres volume alongside the other Docker-managed volumes, and mounted subfolders of `$GRAPHISTRY_HOME/data`. Data like web login credentials are encrypted in Postgres (standard Django), with random values generated on first system start and recorded in your `${GRAPHISTRY_HOME}/data/config/custom.env`. See the migration sections for more on each. Several containers have additional named volumes used for caching purposes and, like Postgres, are managed by Docker.

