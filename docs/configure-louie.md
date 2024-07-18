# Configure Louie
## Oauth2

Louie is an oauth2 client to nexus

When graphistry creds are provided as env vars, auth gets skipped

To use a private graphistry server:
* Register a client app in nexus admin:
  * https://github.com/graphistry/graphistry/wiki/OAuth2-Client-Setup
* Set .env oauth2 settings as per .env.example

You may need to remove `lui_*` cookies (browser devtools -> application -> cookies)

## Use Louie with local Nexus
Alter the /etc/hosts to add host.docker.internal to the 127.0.0.1 hostname
For example:
```
127.0.0.1	localhost host.docker.internal
```
1. Get local nexus online
2. Create an admin account
3. Set up Oauth2 following steps in section [Oauth2](#oauth2)

### Databricks Connector Setup In Nexus
1. Setup encryption and signing environment in `.envs/.development/custom.env` or `.envs/.production/custom.env`

run `compose/etc/scripts/cred-gen.sh >> ./data/config/custom.env` to create the following enviromental varible
```bash
# check with Koa the correct values for below variables
GRAPHISTRY_NEXUS_ENCRYPTION_KEYS=""
GRAPHISTRY_NEXUS_SIGNING_KEY=""
GRAPHISTRY_NEXUS_SIGNING_SALT=""
```
2. Create connector. Replace `connector_name` `connector_host` `token` `workspace_id`. This will print out `your_connector_id` (will need this later)
```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=create_connector ./compose/etc/scripts/nexus-command.sh connector_name Databricks connector_host token workspace_id

```

#### Enviroment variable pairing
The following enviramental variable pairs need to have the same value between Louie and Nexus
|Louie|Nexus|
|:-- |:-- |
GRAPHISTRY_ENCRYPTION_KEYS|GRAPHISTRY_NEXUS_ENCRYPTION_KEYS
GRAPHISTRY_SIGNING_KEY|GRAPHISTRY_NEXUS_SIGNING_KEY
GRAPHISTRY_SIGNING_SALT|GRAPHISTRY_NEXUS_SIGNING_SALT

#### Comparison Between Databricks Enviromental Variable In Louie Vs Connector In Nexus
|Databricks Enviromental Variable In Louie|Connector Keyjson In Nexus|
|:-- |:-- |
DATABRICKS_CONNECTOR_ID | connector.connector_id
DATABRICKS_OAUTH_CLIENT_ID | connector.keyjson["databricks_oauth_client_id"]
DATABRICKS_SHARED_METADATA | connector.keyjson["share_metadata"]
SPARK_TOKEN | connector.keyjson["token"]
SPARK_HOST | connector.keyjson["host"]
SPARK_WORKSPACE_ID | connector.keyjson["workspace_id"]


#### PAT import (Optional for now if pats created in previous step - data import for future to rotate all the PAT - Nexus PR is not merged yet)

1. for pats replace `apps/core/nexus/common/management/commands/dummy.csv` with your csv file content
2. run django command (pats)

```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=create_org_pats ./compose/etc/scripts/nexus-command.sh
```

### Databricks Connector Setup In Louie
Check script in [Step 2](#databricks-connector-setup-in-nexus) for `your_connector_id` value or go to Nexus admin page: `your_host/admin/pivot/connector/`
1. Setup Enviroment in `.env`
```bash
# check with Koa the correct values for below variables
GRAPHISTRY_ENCRYPTION_KEYS=""
GRAPHISTRY_SIGNING_KEY=""
GRAPHISTRY_SIGNING_SALT=""
SPARK_GRAPHISTRY_SPARK_TOKEN=True
# SPARK_GRAPHISTRY_PAT_TABLE=True  # uncomment to use pats
DATABRICKS_CONNECTOR_ID="your_connector_id"
```
2. run louie
```bash
./dc build g; ./dc up g
```