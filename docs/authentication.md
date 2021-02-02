# Graphistry Authentication

This document covers Graphistry's authentication system with respect to architecture, usage, and configuration.

It also touches on coarse authorization decisions where relevant. However, authorization is generally beyond the scope of this document.

See also [security hardening](configure-security.md), [general configuration](configure.md), [manual user account creation](user-creation.md), and [thread model](threadmodel.md).

## Architecture

Graphistry authentication uses 3 standard web layers:

* Reverse proxy: Caddy (`caddy`)
  * Web and API calls are initially reverse-proxied through reverse proxy Docker service `caddy`
  * The Caddyfile and docker-compose.yml configurations (Docker virtual network definition) are the primary places for customizing networking
  * TLS: System administrators should [configure automatic and manual TLS as a custom Caddyfile](configure.md#tls)

* Bastion: Nginx (`nginx`)
  * Caddy sends user HTTP requests to the Graphistry-configured reverse proxy Docker service `nginx`
  * It performs a coarse per-service/route authorization  for public / user / staff based on the service being accessed
  * For example, notebook service use currently require staff level permissions
  * Nginx is _not_ exposed for configuration
  
* Authentication service: Django (`nexus`) - CSRF/JWT sessions
  * Web sesssions use HTTP-only `csrftoken` and `graphistry_jwt` cookies
  * APIs use `jwt` tokens via header `Authorization: Bearer xyz`
  * ... TLS is required for protecting these from MITM attacks
  * By default, authentication is via Graphistry's internal account system
    * Integrating with social/external and internal auth are also possible
    
* Services use JWT tokens
  * They will translate csrf to JWT as needed
  * Resources having corresponding protected metadata:
    * Resource request handlers take a JWT/csrf and check it
  * Services maintain the JWT token as part of their request context for passing to resource requests
  * Services are written following an object-capability paradigm:
    * Having a value gives authority to read/write/call it
    * ... As does passing it, or having/passing a csrf/jwt credential authorized for it
    
## Usage

* The first user to create an account will be given an administrator role. This may vary, such as AWS Marketplace does have an initial account: `admin` / `i-theInstanceID`. 

* Subsequent user registration follows a configurable policy ([see user creation](user-creation.md)). By default, only the administrator can invite subsequent users. The administrator may want to open registration or manually elevate the role of different users.

* API users, upon getting an account, will make their code [programmatically generate short-lived JWT tokens and refresh them](https://hub.graphistry.com/docs/api/1/rest/auth/#auth2).


## Configuration
  
The most typical authentication configurations are:

1. Set TLS via `Caddyfile`, with optional manual TLS credential volume mount in the `docker-compose.yml`. See TLS [docs](configure.md#tls-caddyfile).

2. Open/close account registration and invite users. See [user creation docs](user-creation.md). Contact staff for more advanced options, such as social logins and LDAP/SAML.
