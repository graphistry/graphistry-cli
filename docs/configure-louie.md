# Configure Louie
## OAuth2 
Louie serves as an OAuth2 client to Nexus. When Graphistry credentials are provided as environment variables, authentication is bypassed. To utilize a private Graphistry server, follow these steps: 
 
- Register a client app in the Nexus admin panel: [OAuth2 Client Setup](https://github.com/graphistry/graphistry/wiki/OAuth2-Client-Setup) 
- Configure OAuth2 settings in the  .env  file as per the  .env.example  
 
If necessary, remove  lui_*  cookies using browser developer tools (navigate to Application -> Cookies). 

## How to Use Connector Management Script
This script facilitates CRUD operations on connectors within the Graphistry system.
### Prerequisites

Ensure you have the following environment variables set:

    GRAPHISTRY_USERNAME
    GRAPHISTRY_PASSWORD
    GRAPHISTRY_NEXUS_SIGNING_KEY
    GRAPHISTRY_NEXUS_SIGNING_SALT
    CONNECTOR_NAME

### Usage

1. Create a new connector
```bash
GRAPHISTRY_BASE_PATH=http://localhost KEYJSON='{}' CONNECTOR_TYPE=Databrics CONNECTOR_NAME="MyConnector" ACTION=create ./connector_management.sh
```
2. Update an existing connector
```bash
GRAPHISTRY_BASE_PATH=http://localhost KEYJSON='{}' CONNECTOR_TYPE=Databrics CONNECTOR_ID="connector_id" CONNECTOR_NAME="UpdatedConnector" ACTION=update ./connector_management.sh

```
3. Delete a connector
```bash
GRAPHISTRY_BASE_PATH=http://localhost CONNECTOR_ID="connector_id" ACTION=delete ./connector_management.sh

```
4. Get a connector
```bash
GRAPHISTRY_BASE_PATH=http://localhost CONNECTOR_ID="connector_id" ACTION=get ./connector_management.sh

```
5. List all connectors
```bash
GRAPHISTRY_BASE_PATH=http://localhost ACTION=list ./connector_management.sh

```
 
## Use Louie with Local Nexus 
To configure Louie with a local Nexus setup, modify the  /etc/hosts  file to include  `host.docker.internal`  alongside  `127.0.0.1` :
For example:
```
127.0.0.1	localhost host.docker.internal
```
1. Ensure local Nexus is online. 
2. Create an admin account. 
3. Set up OAuth2 following the steps outlined in the [OAuth2](#oauth2) section.

### Connector Management Command 
This Django management command facilitates CRUD operations (Create, List, Show, Edit, Delete) on the Connector model. 
 
#### Usage 

1. Run the management command with the specified actions:
    - `create`: Create a new connector.
    - `list`: List all existing connectors.
    - `show --id <connector_id>`: Show details of a specific connector.
    - `edit --id <connector_id>`: Edit an existing connector.
    - `delete --id <connector_id>`: Delete a connector.

2. Available arguments:
    - `--id`: Connector ID for show, edit, or delete actions.
    - `--name`: The name of the connector.
    - `--type`: The type of the connector.
    - `--host`: The host for the connector.
    - `--token`: The authentication token for the connector.
    - `--workspace_id`: The workspace ID for the connector.

#### Examples

1. Create a new connector:
```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=manage_connector ./compose/etc/scripts/nexus-command.sh create --name "ConnectorName" --type "ConnectorType" --host "ConnectorHost" --token "AuthenticationToken" --workspace_id "WorkspaceID"
```
2. List all connectors:
```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=manage_connector ./compose/etc/scripts/nexus-command.sh list
```
3. Show details of a specific connector:
```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=manage_connector ./compose/etc/scripts/nexus-command.sh show --id <connector_id>
```
4. Edit an existing connector:
```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=manage_connector ./compose/etc/scripts/nexus-command.sh edit --id <connector_id> --name "NewName" --type "NewType"
```
5. Delete a connector:
```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=manage_connector ./compose/etc/scripts/nexus-command.sh delete --id <connector_id>
```

#### Notes

- Ensure appropriate permissions are in place to perform CRUD operations on the Connector model. 
- Provide all required arguments for each action to prevent errors. 
 
### Databricks Connector Setup In Nexus 
1. If you not yet has encription key(GRAPHISTRY_NEXUS_ENCRYPTION_KEYS): Establish encryption and signing environment in  .envs/.development/custom.env  or  .envs/.production/custom.env . Run the following script to create the necessary environmental variables:
```bash
compose/etc/scripts/cred-gen.sh >> ./data/config/custom.env
```
```bash
# check with Koa the correct values for below variables
GRAPHISTRY_NEXUS_ENCRYPTION_KEYS=""
GRAPHISTRY_NEXUS_SIGNING_KEY=""
GRAPHISTRY_NEXUS_SIGNING_SALT=""
```
2. Create a connector using the following command:
```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=manage_connector ./compose/etc/scripts/nexus-command.sh create --name "ConnectorName" --type "ConnectorType" --host "ConnectorHost" --token "AuthenticationToken" --workspace_id "WorkspaceID"

```

### Environment Variable Pairing 
Ensure the following environmental variable pairs have identical values between Louie and Nexus: 
 
| Louie | Nexus | 
|:-- |:-- | 
| GRAPHISTRY_ENCRYPTION_KEYS | GRAPHISTRY_NEXUS_ENCRYPTION_KEYS | 
| GRAPHISTRY_SIGNING_KEY | GRAPHISTRY_NEXUS_SIGNING_KEY | 
| GRAPHISTRY_SIGNING_SALT | GRAPHISTRY_NEXUS_SIGNING_SALT | 
 
### Comparison Between Databricks Environmental Variables in Louie and Connector in Nexus 
| Databricks Environmental Variable in Louie | Connector Keyjson in Nexus | 
|:-- |:-- | 
| DATABRICKS_CONNECTOR_ID | connector.connector_id | 
| DATABRICKS_OAUTH_CLIENT_ID | connector.keyjson["databricks_oauth_client_id"] | 
| DATABRICKS_SHARED_METADATA | connector.keyjson["share_metadata"] | 
| SPARK_TOKEN | connector.keyjson["token"] | 
| SPARK_HOST | connector.keyjson["host"] | 
| SPARK_WORKSPACE_ID | connector.keyjson["workspace_id"] | 

### Louie env var (static vs dynamic connector)
<table>
  <tr>
    <th>Static Connector Confugiration</th>
    <th>Dynamic Connector Confugiration</th>
  </tr>
  <tr>
    <td>
        &nbsp;
        DATABRICKS_SHARED_METADATA=True
        <br>&nbsp;
        SPARK_TOKEN="token"
        <br>&nbsp;
        SPARK_HOST="host"
        <br>&nbsp;
        SPARK_WORKSPACE_ID="workspace_id"
    </td>
    <td>
        &nbsp;
        GRAPHISTRY_ENCRYPTION_KEYS=""
        <br>&nbsp;
        GRAPHISTRY_SIGNING_KEY=""
        <br>&nbsp;
        GRAPHISTRY_SIGNING_SALT=""
        <br>&nbsp;
        SPARK_GRAPHISTRY_SPARK_TOKEN=True
        <br>&nbsp;
        # SPARK_GRAPHISTRY_PAT_TABLE=True  # uncomment to use pats
        <br>&nbsp;
        DATABRICKS_CONNECTOR_ID="your_connector_id"
    </td>
  </tr>
</table>

 
### PAT Import (Optional for now if PATs were created in a previous step - data import for future to rotate all the PAT - Nexus PR is not merged yet) 
1. For PATs, replace  apps/core/nexus/common/management/commands/dummy.csv  with the content of your CSV file. 
2. Execute the Django command for PATs:

```bash
GRAPHISTRY_HOME=compose/ CMD_NAME=create_org_pats ./compose/etc/scripts/nexus-command.sh
```

### Databricks Connector Setup In Louie 
Refer to the script in [Step 2](#databricks-connector-setup-in-nexus) to obtain the  your_connector_id  value or visit the Nexus admin page at  your_host/admin/pivot/connector/ . 
 
1. Set up the environment in the  .env  file:
```bash
# check with Koa the correct values for below variables
GRAPHISTRY_ENCRYPTION_KEYS=""
GRAPHISTRY_SIGNING_KEY=""
GRAPHISTRY_SIGNING_SALT=""
SPARK_GRAPHISTRY_SPARK_TOKEN=True
# SPARK_GRAPHISTRY_PAT_TABLE=True  # uncomment to use pats
DATABRICKS_CONNECTOR_ID="your_connector_id"
```
2. Run Louie:
```bash
./dc build g; ./dc up g
```
