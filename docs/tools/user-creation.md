# User Creation

See also [general configuration](../app-config/configure.md) and [authentication](../security/authentication.md)

## Account Creation Model

It is easy to securely add users, and we generally recommend [giving users only as much access as they need](https://en.wikipedia.org/wiki/Principle_of_least_privilege):

* Graphistry temporarily starts with **Open Registration**
* The first user to register automatically gains the **superuser** and **staff** roles, and the system automatically switches to **Invite-Only**
* **superuser** users can create new users and assign them roles, including **superuser** and **staff**
* ... This is easiest via making an organization and adding them from the members page, see below
* Every user can create **personal access keys** for creating visualizations
* **staff** users also get access to the shared Jupyter notebook server, private dashboards, and the team investigation automation tool
* **superuser** users can also turn open registration back on, and give newly self-registered users the role **staff**
* Users can create organizations
* [SSO can be enabled](../security/authentication.md) site-wide or per-organization, such as when there are multiple identity providers
* Organization administrators can invite existing site users into their organization
* Organization administrators can choose whether SSO users can self-join the organization or require an invitation
* Site administrators can create users from an organization page, who then get added to the organization at the same time

## Create Initial User: Admin 1

| Step | Diagram |
| ---: | :------ |
| Upon starting Graphistry the first time, simply sign up. Take care to record your login/pwd. | <img src="img/signup.png" height="300"> |

If on AWS, see AWS-specific instructions for default admin configuration

## Add Users:

Graphistry supports user creation and user invitation, which can be used together.

Creating a user is typically performed from within an organization, and for users who do not have SSO.

Separately, an existing user or SSO user may also be invited into a specific orgnaization. If email is configured, they will be emailed, otherwise, they will be given a link. When they already have an account, they will be asked whether they want to join the organization. If they do not have an account, they will be asked whether they want an account, and upon creation, automatically accept the invite to join the organization as well.

To create or invite a user:

* Menu => Manage Organizations => Create Organization
* Menu => Manage Organizations => organization's Members page => Create or Invite user 

## Empower User as Site Staff/Admin

| Step | Diagram |
| ---: | :----- |
| Go to the **Admin Portal**    | <img src="img/admin.png" height="150">     |
| Open the **Users** manager    | <img src="img/cfg_users.png" height="150"> |
| Set **Permissions**, typically unchecking **staff** and **superuser** | <img src="img/set_roles.png" height="300"> |
| **Save**                      |                                            |

Congrats, your user can now log in!

## Provide API Keys

All Graphistry account owners get API access. They can be used with SSO or username/password, but we recommend using revocable personal access keys.

* Users may generate one or more personal keys on their profile page
* API keys are revocable

Under-the-hood, the personal access keys are used to intiate time-limted JWT sessions.

## Enable Open Registration

To allow users to self-register, in the admin panel's constance configuration, enable `IS_SIGNUPS_OPEN_AFTER_FIRST`

For new users to gain access to the team notebook server and the investigation tool, you will need to give them **staff** permissions.



