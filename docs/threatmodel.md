# Threat Model

Graphistry is largely a standard enterprise webapp and uses modern design patterns, infrastructure, tools, & frameworks. It can be run through Graphistry Hub (Graphistry-hosted multi-tenant public cloud SaaS), automatically self-hosted in public clouds (AWS/Azure Marketplace single-VM AMIs), manually self-hosted in public cloud (docker-compose or kubernetes), or self-hosted on-prem (including air-gapped). Details vary depending on distribution choice and configuration.

Interesting surface areas include: frontend & backend (app + system), the network, exported logs, the use of GPUs, and the distinctions between authenticated users (privileged analyst teams) vs. network users (shared visualization recipients. Beyond the scope of this document is securing non-Graphistry systems, e.g., data science notebooks or your own database.

Useful infrastructure controls include: your network controls (cloud and firewall), your database's security controls, and in Graphistry, the account system, the API token system, the configurable reverse proxy, Docker containers/networking/volumes, and for custom scenarios, the auth modules.

## Attacker capabilities

Self-hosted Graphistry is built with standard enterprise web attackers:

* Network attackers that are unauthenticated
* Compromised non-admin users accounts and API tokens

The threat model excludes:

* QoS attacks - contact for Graphistry Cloud which we manage
* Admin takeovers at the level of the server or account system
* Database attacks through misconfigured connectors, e.g., giving a Splunk analyst the ability to QoS attack Splunk through overly broad connector permissions

## Role Hierarchy: Graphistry 1.0 vs. 2.0

The 2.0 release (2019) expands from single-admin & untrusted web users to account-based:

#### 1.0 (< 2019): Publishers and Viewers
Aimed at both dedicated developer embedding scenarios and small trusted team settings where a trusted group of publishers (admins) analyzes data and publishes results to general network users.

* Admins:
  * Cases and Templates: Full - create, write, read, run
  * Visualizations: Full - create, write, read, run, share
* Viewers (web users):
  * Visualizations: read, copy-on-write

#### 2.0 (>= 2019): Admins, Users, and Viewers
The 2.0 release expands authentication and authorization options for common shared enterprise analyst tool settings:

* OS System admin: Full access
* Account admin: 
  * Full: Connector config, logs, cases, templates, visualizations, accounts, Jupyter notebook account
  * Cases & Templates are prioritized for safe User-level access in 2020
* User: 
  * Visualization (owned): create, read, run, edit, share
  * Visualization (shared): receive, read, run, copy-on-edit, share
  * Shared Jupyter notebook account: full
* Viewer: 
  * Visualization (shared): receive, read, run, copy-on-edit, share
  * Viewers are *unauthenticated*; control at level of the reverse proxy or your network


## Assets to protect
* OS and logs
* System configuration, including optional database and API connectors
* User account data
* User API tokens
* User-authored visualizations, investigations, and templates
* Optional: notebooks when using the Graphistry-provided Jupyter instance


## Authentication

### Web
* TLS: Auto-TLS (LE) or custom cert 
* JWT authentication for Browser Sessions (HTTP-only headers) and REST API tokens
* JWT token maps to account & role: Admin, User, Viewer (= unauthenticated)

### System

* OS access: Owner-controlled


## Attack surfaces
* Supply chain: Packaged dependencies, binary delivery
* HW+OS: Out of scope (contact for data-at-rest)
* Exported logs
* Reverse proxy (Caddy, Nginx)
* Web auth
* Authenticated user: All web routes in case of a non-admin compromise
* Authenticated user: Notebooks, which exposes notebook data volume mount and allows arbitrary code in the (restricted) notebook container
* Network user: Access to viz service and volume mounts
* Individual tools & frameworks, especially Docker, Caddy/Nginx, NodeJS, Python, Nvidia RAPIDS, & Jupyter

## Architecture: Defense-in-depth
* Dependencies:
  * Explicit versioning
  * Regular automatic scanning: npm audit, docker, ...
  * Regular version updates
* Delivery:
   * Software delivered via signed AWS S3 URL or cloud AMI/Marketplace
* Config: 
  * Sensitive configs are marked and considered when logged
  * App reads from environment variable or config mounts
  * Warning: Graphistry logs are secured for levels INFO+; do not store logs in TRACE and DEBUG modes
* Networking: Reverse proxy, firewalls, TLS
  * Firewall: Enterprise and cloud firewall settings are typically used to control Viewer-level access (ex: VPN-only) and System access (ex: SSH)
  * Bastion: We use a two-layer scheme: outward is the small and friendly Caddy system for admins (ex: TLS & sinkholes), and inner is Nginx for app control (ex: JWT enforcement)
  * TLS is necessary for avoiding MITM
* Isolation: Docker, GPU, services
  * Provides isolation from exploits reaching the OS
  * Audit volume mounts and GPU configuration flags for sharing preferences
  * Services are primarily in managed languagues that enforce memory isolation & additional process isolation
  * Where the app does support user-generated code, the app uses conservative safelists and one-time sandboxed interpreters, except for BSQL
* HTTP activity can be logged
* Client
  * User-supplied code is generally prohibited, and the few exceptions are via safelists, e.g, image tags
  * HTTP-only authorization headers and CSRF tokens

## Additional Notes
Contact your SE about additional security configuration at the OS/HW level and ensuring system configuration (log forwarding, configuring/disabling user analytics, ...). Likewise, we are always happy to discuss security feature requests.
