# Threat Model

Graphistry is largely a standard enterprise webapp and uses modern design patterns, infrastructure, tools, & frameworks.

Interesting surface areas include: use of GPUs, Jupyter notebooks, and the distinctions between authenticated users (privileged analyst teams) vs. network users (shared visualization recipients.)

Interesting infrastructure and controls include: Docker containers & networking & volumes, Nginx routing, and Django auth modules.

The Embedding API is out of scope for this document.

## Assets
* System
* Connector config
* Authored investigations + templates + visualizations
* Notebooks
* Logs

## Role hierarchy with asset access
* Admins: DB connector config (r/w/x), logs (r/w)
* Analyst team: connectors (r/x), cases/templates/notebooks (r/w/x), visualizations (r/w/x)
* Network user: visualizations (r/x)

## Authentication
* Web access: pluggable web auth (nginx/django)
* OS access: owner-controlled; recommend firewall restricts to http/https/ssh

## Authorization:
* Admins: OS access secured by owner (recommend: firewall + SSH key)
* Analyst: Web login (enabled by admin), all analysts share web-based investigations & automations & notebooks
* Network user: Generated visualizations shared via web keys with any network-connected user, with options for  read-only and read+write

## Attack surfaces:
* HW+OS: Out of scope (contact for data-at-rest)
* Supply chain: Delivered binary & packaged dependencies
* Logs
* Web auth
* Authenticated user: All web routes
* Authenticated user: Notebooks, which exposes notebook data volume mount and allows arbitrary code in the (restricted) notebook container
* Network user: Access to viz service and volume mounts
* Individual tools & frameworks, especially Docker, Nginx, NodeJS/Fastify/Express, Python, Nvidia RAPIDS, & Jupyter

## Architecture: Defense-in-depth & trust boundaries
* Dependencies are explicitly versioned, and regularly updated based on community scan warnings (npm audit, docker, ...)
* Software delivered via signed AWS S3 URL or cloud AMI/Marketplace
* Config: App reads from environment variable or config mounts. Explicit schema tags sensitive values, and app respects those tags when emitting to logs or the UI.
* Isolated docker services with configured volume mounts: Resources are physically seperated, including limiting which mounts are exposed to the services exposed to network users vs. authenticated app regions.
* Nginx container controls routes, including enforcing auth on public routes
* Service runtimes are primarily in managed languagues that enforce memory isolation & additional process isolation
* Where the app does support providing code, approach taken of either whitelisting (e.g., client query parameters), and app-level or ephemeral interpreters (vs. reusing persistent DBs)
* HTTP activity is logged

## Additional Notes
Contact your SE about additional security configuration at the OS/HW level and ensuring system configuration (log forwarding, configuring/disabling user analytics, ...). Likewise, we are always happy to discuss security feature requests.
