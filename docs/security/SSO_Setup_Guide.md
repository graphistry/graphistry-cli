# Graphistry Enterprise Server - SSO Configuration Guide

## Overview

Graphistry Enterprise Server supports Single Sign-On (SSO) through [OIDC (OpenID Connect)](https://openid.net/connect/) providers such as **Okta**, **Entra**, **Auth0** and others. You can configure SSO **site-wide** for all users or **per organization**, depending on your multi-tenancy needs.

This guide walks you through configuring SSO in Graphistry. 
---

## Prerequisites

Before setting up SSO:

* Deploy Graphistry Enterprise Server (self-hosted or cloud)
* Ensure TLS is configured properly (especially when using external proxies or load balancers) 
* Set the correct **site domain** in your Graphistry configuration

---

## Configuration Paths

SSO setup can be done **site-wide** or at the **org-level**
### 1. Enable SSO using Site-wide SSO

Note:  Graphistry Hub users are not able to configure Site-wide SSO, see the Organization-specific config below. 

1. click the admin user drop-down menu and select **Manage site-wide SSO** 

* (Recommended) Disable traditional account creation
* (Recommended) Set up outgoing email (for invites and notifications)

### 2. Organization-specific SSO

Note:  Graphistry Hub users are required to have paid Organization account. [Sign up for an Organization account on graphistry hub](https://hub.graphistry.com/users/stripe/select_org/team-annually/). 

1. Create a new organization by clicking the username drop-down menu and selecting **Manage Organizations** 
2. Click the plus (+) symbol to create a new organization
3. After new org has been created, click the **shield icon** in the organization config page to access the SSO configuration page for the organization.   


# Configure the identity provider (OIDC details)

---

## Identity Provider (IdP) Setup

Graphistry supports **OIDC-compliant providers**. Setup generally includes:

- Refer to your IdP's documentation for creating OIDC apps and obtaining credentials.
- Choosing the correct SSO IdP template
- Create a name for IdP connection
- Set the IdP Hostname and Client ID (Note: some providers may require additional fields)
- Testing the SSO connection 

Follow these steps to configure the IdP connection: 

1. Give the provider a name in the **IDP Name** field. 
2. Select **Enabled** to enable this IdP login. 
3. In the **SSO provider** select the provider (e.g., Okta, Auth0, KeyCloak, Microsoft Entra, Microsoft ADFS, or Custom)
4. For **Host URL** use the Base URL of SSO IDP used for redirection.
5. Enter the **Client ID** assigned to the Application from the IdP provider. 
6. Graphistry will autofill the rest (OpenID URL, Profile URL, etc.)
7. Save and test by opening an incognito window to graphistry server and clicking login SSO. 


---

## Email Setup (Recommended)

To fully support invitations and notifications:

* Configure SMTP settings in Graphistry
* Enables sending:

  * SSO invite emails
  * Organization join links
  * Admin alerts

---

## Admin Tools for SSO Users

* **User Creation by Admin**: Site/Org admins can pre-create accounts for users
* **User Invitations**: Org admins can send invite links
* **User Management**: View/manage SSO-linked users via **Manage Organizations**

---

## Using External Proxies or Load Balancers

If deploying behind a proxy:

* Ensure your **Graphistry site domain** is correctly set
* Confirm that **TLS termination** is handled properly
* Double-check redirect URIs for your identity provider

---

## Additional Resources

* [Configuration Docs – SSO Section](https://graphistry-admin-docs.readthedocs.io/en/latest/app-config/configure.html#sso)
* [SSO Authentication Flow](https://graphistry-admin-docs.readthedocs.io/en/latest/security/authentication.html)
* [OIDC Server Setup](https://graphistry-admin-docs.readthedocs.io/en/latest/security/SSO.html)
* [User Management with SSO](https://graphistry-admin-docs.readthedocs.io/en/latest/tools/user-creation.html)

---

## Recommendations for Self-Hosting

* Set up email (SMTP) for invite flows
* Enforce site-wide SSO where appropriate
* Disable non-SSO login to harden access
* Decide on auto-join policy per organization
* Use secure TLS and proper proxy configuration

---

## Need Help?

Contact [Graphistry Support](http://graphistry.zendesk.com/) for questions on setting up your SSO configuration or to troubleshoot SSO issues.

