# Graphistry Authentication

This document covers Graphistry's authentication system with respect to architecture, usage, and configuration.

It also touches on coarse authorization decisions where relevant. However, authorization is generally beyond the scope of this document.

See also [security hardening](configure-security.md), [general configuration](../app-config/configure.md), [manual user account creation](../tools/user-creation.md), and [threat model](threatmodel.md).

## Architecture

Graphistry authentication uses standard web software layers:

* Container: Docker with `./graphistry` wrapper (wraps docker compose)
  * Determine ports for http and/or https

* Reverse proxy: Caddy (`caddy`)
  * Web and API calls are initially reverse-proxied through reverse proxy Docker service `caddy`
  * The Caddyfile and docker-compose.yml configurations (Docker virtual network definition) are the primary places for customizing networking
  * TLS: System administrators should [configure automatic and manual TLS as a custom Caddyfile](../app-config/configure.md#tls)

* Bastion: Nginx (`nginx`)
  * Caddy sends user HTTP requests to the Graphistry-configured reverse proxy Docker service `nginx`
  * It performs a coarse per-service/route authorization  for public / user / staff based on the service being accessed
  * For example, notebook service use currently require staff level permissions
  * Nginx is _not_ exposed for configuration
  
* Authentication service: Django (`nexus`) - CSRF/JWT cookies and sessions
  * Web sesssions use HTTP-only `csrftoken` and `graphistry_jwt` cookies
  * APIs use `jwt` tokens via header `Authorization: Bearer xyz`
  * ... TLS is required for protecting these from MITM attacks
  * By default, authentication is via Graphistry's internal account system
    * Integrating with social/external and internal auth are also possible

* Single sign-on (SSO)
  * Graphistry supports OIDC-compliant single sign-on (SSO)
  * Menu: Admin Portal -> Settings -> Config -> IS_SSO_SIGNUP: Enable, save
  * Manu:
      * Site-wide SSO: Go to Manage Site
      * Organization-specific:  Go to Manage Organizations -> Security icon (SSO)
  * Configure the identity provider as instructed
      * For popular providers, pick a template, fill in the host name, and get the rest prefilled
    
* Services use JWT tokens
  * They will translate csrf to JWT as needed
  * Resources having corresponding protected metadata:
    * Resource request handlers take a JWT/csrf and check it
  * Services maintain the JWT token as part of their request context for passing to resource requests
  * Services are written following an object-capability paradigm:
    * Having a value gives authority to read/write/call it
    * ... As does passing it, or having/passing a csrf/jwt credential authorized for it

 * Browser security headers
   * Unconfigured servers do nto have TLS
   * [Add a TLS certificate](../app-config/configure.md#tls) enables TLS
   * Further consider adding [additional security headers](../app-config/configure.md#caddy)
   * Cross-origin embedding for unauthenticated visualizations is enabled by default
   * To enable cross-origin embedding of authenticated visualizations, [modify the cookie options](../app-config/configure.md#application-servers)
    
## Usage

* The first user to create an account will be given an administrator role. This may vary, such as AWS Marketplace does have an initial account: `admin` / `i-theInstanceID`. 

* Subsequent user registration follows a configurable policy ([see user creation](../tools/user-creation.md))
    * By default, only the administrator can invite subsequent users
    * The administrator may want to open account creation or manually elevate the role of different users
    * Organization administrators may control whether their organization is open for joining at all, including whether SSO users can self-join or require an explicit invitation

* API users, upon getting an account, will make their code [programmatically generate short-lived JWT tokens and refresh them](https://hub.graphistry.com/docs/api/2/rest/auth/).


## Configuration
  
The most typical authentication configurations are:

1. Set TLS via `Caddyfile`. See TLS [docs](../app-config/configure.md#tls).

2. Open/close account registration and invite users. See [user creation docs](../tools/user-creation.md). Contact staff for more advanced options, such as social logins and LDAP/SAML.

3. Enable cross-origin embedding of authenticated visualizations by [editing cookie settings](../app-config/configure.md#application-servers) (requires TLS)

4. Enable SSO
