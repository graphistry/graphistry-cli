# Managed Connector CLI

Graphistry-managed connectors simplify more secure secret management and automation patterns than storing credentionals as environment variables. This document describes REST-based remote management using a bash script. It walks through the needed secret management and configuration. The examples are for Databricks.

You can manage Louie connectors stored in Graphistry using the local console CLI from a Graphistry server or remotely via the REST API. The REST API is easier to start with. For convenience, we include bash scripts for using the remote REST API. Functionalities include creating, updating, deleting, getting, and listing connectors.

## Prerequisites

### Remote REST API bash scripts: Python cryptography library

The REST curl bash scripts invoke the Python cryptography library.

The script uses the Python cryptography library to decrypt keyjson. Install the library using one of the following commands:
```bash
pip install cryptography
```
or
```bash
pip3 install cryptography
```

### Environment variables

#### Needed keys: Remote API client configuration

To use the relevant management APIs, ensure you have the following environment variables:

```bash
# For administration scripts
export GRAPHISTRY_USERNAME=username
export GRAPHISTRY_PASSWORD=pass
export GRAPHISTRY_BASE_PATH=http://localhost

# For signing
export GRAPHISTRY_ENCRYPTION_KEYS=encryption_key
export GRAPHISTRY_NEXUS_SIGNING_KEY=signing_key
export GRAPHISTRY_NEXUS_SIGNING_SALT=salt_key
```

Additionally, use or get a copy of `$GRAPHISTRY_HOME/etc/scripts/connector_management.sh`

#### Needed keys: Graphistry server configuration

Your Graphistry server uses similarly named keys with the same values:

```bash
# For administration scripts
export GRAPHISTRY_USERNAME=username
export GRAPHISTRY_PASSWORD=pass
export GRAPHISTRY_BASE_PATH=http://localhost

# For signing
export GRAPHISTRY_NEXUS_ENCRYPTION_KEYS=encryption_key
export GRAPHISTRY_NEXUS_SIGNING_KEY=signing_key
export GRAPHISTRY_NEXUS_SIGNING_SALT=salt_key
```

Note the difference of `GRAPHISTRY_NEXUS_ENCRYPTION_KEYS` vs `GRAPHISTRY_ENCRYPTION_KEYS`. Future upgrades will normalize on dropping the term `_NEXUS_`.

#### Find or generate signing keys

For self-hosted Graphistry server users, you need to generate encryption and signing keys. If you are using Graphistry Hub, please contact Graphistry staff to obtain your keys.

The keys are: `GRAPHISTRY_NEXUS_ENCRYPTION_KEYS`, `GRAPHISTRY_NEXUS_SIGNING_KEY`, and `GRAPHISTRY_NEXUS_SIGNING_SALT`.

Check if you already have them set in your `./data/config/custom.env`, and read on to replace them if desired:

```bash
cat ./data/config/custom.env | grep -E "GRAPHISTRY_NEXUS_ENCRYPTION_KEYS|GRAPHISTRY_NEXUS_SIGNING_KEY|GRAPHISTRY_NEXUS_SIGNING_SALT"
```

This should list your keys. To rotate them, delete them from the file and continue.

To generate and append the necessary environmental variables to your `./data/custom.env`, run:

```bash
{ echo ""; bash -c "$(sed '1 a\set +x' ./etc/scripts/cred-gen.sh)" | grep -E "GRAPHISTRY_NEXUS_ENCRYPTION_KEYS|GRAPHISTRY_NEXUS_SIGNING_KEY|GRAPHISTRY_NEXUS_SIGNING_SALT"; }
 >> ./data/custom.env
```

Running the immediately prior checking script should find and list your keys.

Once confirmed, restart the Nexus service to switch to the new signing keys:

```bash
./release up -d --force-recreate --no-deps nexus
```

## How to Use: Remote bash client over the REST API

The bash script calls the underlying remote REST APIs on your behalf, including Python callouts for encrypt. Use it with various combinations of environment variables and actions to perform specific operations on connectors.

### Location

You may find a copy of the standalone bash REST API client at `$GRAPHISTRY_HOME/etc/scripts/connector_management.sh`

The following examples assume you are calling it from `$GRAPHISTRY_HOME`. You can call it from anywhere, including on other computers with network access to Graphistry.

### Settings as environment variables

Control settings and configuration by defining the following environment variables during the script invocation.

Client configuration environment variables detailed above:


- `GRAPHISTRY_BASE_PATH=http://localhost`
- `GRAPHISTRY_USERNAME`
- `GRAPHISTRY_NEXUS_SIGNING_SALT`
- `GRAPHISTRY_PASSWORD`
- `GRAPHISTRY_ENCRYPTION_KEYS` (note no `NEXUS`)
- `GRAPHISTRY_NEXUS_SIGNING_KEY`

Command environment variables:


- `ACTION`: Action to perform (`create`, `update`, `delete`, `get`, `list`, `upsert_pat`, `delete_pat`, `delete_all_pats`, `update_all_pats`). The default action is list.
- `KEYJSON`: JSON data containing connector configuration value. The default is an empty JSON object.
- `CONNECTOR_TYPE`: Type of the connector. The default value is Databricks.
- `CONNECTOR_ID`: The ID of the connector. This can be left empty for certain actions.
- `CONNECTOR_NAME`: The name of the connector.
- `PAT_KEY`: The key(username) for the Personal Access Token (PAT) to be managed.
- `PAT_VALUE`: The value for the PAT to be managed.
- `PATS_JSON`: JSON string containing multiple PATs for bulk updates.
- `PATS_CSV`: Path to a CSV file containing multiple PATs for bulk updates.


### Additional Help

For further assistance and detailed usage instructions, refer to the following command:

```bash
ACTION=help ./etc/scripts/connector_management.sh
```

### Top commands

#### List connectors

To list all existing connectors, use the following example command:

```bash
ACTION=list ./etc/scripts/connector_management.sh
```

#### Get connector

To retrieve details of a specific connector, use the following example command:

```bash
ACTION=get CONNECTOR_ID="connector_id" ./etc/scripts/connector_management.sh
```

#### Create connector

To create a new connector, use the following example command for Databricks

```bash
ACTION=create ORG_NAME=my_org_123 CONNECTOR_NAME="MyDatabricksConnector" CONNECTOR_DETAIL='{"host": "abc123.cloud.databricks.com", "workspace_id": "xyz456"}' KEYJSON='{"pats": {"user1": "aa11", "user2": "bb22"}}' ./etc/scripts/connector_management.sh
```

#### Update connector

To update an existing connector, use the following example command:

```bash
ACTION=update CONNECTOR_ID="connector_id" CONNECTOR_NAME="UpdatedConnectorName" CONNECTOR_DETAIL='{"host": "abc123-updated.cloud.databricks.com", "workspace_id": "xyz456-updated"}' KEYJSON='{"user1": "updated_pat1", "user2": "updated_pat2"}' ./etc/scripts/connector_management.sh
```

#### Delete connector

To delete a connector, use the following example command:

```bash
ACTION=delete CONNECTOR_ID="connector_id" ./etc/scripts/connector_management.sh
```

### Databricks

Databricks connector management is largely via the above generic commands

Additional per-user PAT management is supported through the following Databricks-specific connector commands. When SSO is not an option, this allows storing per-user PAT entries that get automatically applied upon regular Graphistry authentication.

#### Manage one or more Personal Access Tokens (PATs)

To upsert, delete, delete all, or update all PATs associated with a connector, use the following example commands:

```bash
# Upsert a PAT
ACTION=upsert_pat CONNECTOR_ID="sample_connector_id" PAT_KEY="sample_key" PAT_VALUE="sample_value" ./etc/scripts/connector_management.sh

# Delete a PAT
ACTION=delete_pat CONNECTOR_ID="sample_connector_id" PAT_KEY="sample_key" ./etc/scripts/connector_management.sh

# Delete all PATs
ACTION=delete_all_pats CONNECTOR_ID="sample_connector_id" ./etc/scripts/connector_management.sh

# Update all PATs 
ACTION=update_all_pats CONNECTOR_ID="sample_connector_id" PATS_JSON='{"user10":"pat_value"}' ./etc/scripts/connector_management.sh

# Update all PATs using csv file
ACTION=update_all_pats CONNECTOR_ID="sample_connector_id" PATS_CSV='path/to/pats.csv' ./etc/scripts/connector_management.sh
```

#### CSV File Example

```
username,PAT
user123,abc123pat
user456,def456pat
user789,ghi789pat
test1,jkl012pat
```

#### Keyjson with PATs Example

```json
{
    "host": "updated_host_url",
    "pats": {
        "user1": "updated_pat1",
        "user2": "updated_pat2"
    },
    "token": "updated_service_token",
    "workspace_id": "updated_workspace_id"
}
```
