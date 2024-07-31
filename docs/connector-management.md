# Using the Connector Management Bash Script

This guide provides instructions for utilizing the bash script for managing connectors in Graphistry. The script includes functionalities for creating, updating, deleting, getting, and listing connectors. It interacts with a Graphistry API using curl commands and generates JWT tokens for authentication.

## Prerequisites

Ensure you have the following environment variables set:

```bash
export GRAPHISTRY_USERNAME=username GRAPHISTRY_PASSWORD=pass GRAPHISTRY_ENCRYPTION_KEYS=encryption_key  GRAPHISTRY_NEXUS_SIGNING_KEY=signing_key GRAPHISTRY_NEXUS_SIGNING_SALT=salt_key
```
Other environment variables:
- `GRAPHISTRY_BASE_PATH`: The base URL path for the Graphistry API. The default value is http://localhost.
- `KEYJSON`: JSON data containing connector configuration value. The default is an empty JSON object.
- `CONNECTOR_TYPE`: Type of the connector. The default value is Databricks.
- `CONNECTOR_ID`: The ID of the connector. This can be left empty for certain actions.
- `ACTION`: Action to perform (create, update, delete, get, list, upsert_pat, delete_pat). The default action is list.

## How to Use

The bash script can be used with various combinations of environment variables and actions to perform specific operations on connectors. Here are some examples:

### Creating a Connector

To create a new connector, use the following example command:

```bash
ACTION=create CONNECTOR_NAME="MyConnector" KEYJSON='{"host": "host_url", "pats": {"user1": "pat1", "user2": "pat2"}, "token": "service_token", "workspace_id": "workspace_id"}' path_to_script/connector_management.sh
```

### Updating a Connector

To update an existing connector, use the following example command:

```bash
ACTION=update CONNECTOR_ID="connector_id" CONNECTOR_NAME="UpdatedConnector" KEYJSON='{"host": "updated_host_url", "pats": {"user1": "updated_pat1", "user2": "updated_pat2"}, "token": "updated_service_token", "workspace_id": "updated_workspace_id"}' path_to_script/connector_management.sh
```

### Deleting a Connector

To delete a connector, use the following example command:

```bash
ACTION=delete CONNECTOR_ID="connector_id" path_to_script/connector_management.sh
```

### Getting a Connector

To retrieve details of a specific connector, use the following example command:

```bash
ACTION=get CONNECTOR_ID="connector_id" path_to_script/connector_management.sh
```

### Listing Connectors

To list all existing connectors, use the following example command:

```bash
ACTION=list path_to_script/connector_management.sh
```

### Managing Personal Access Tokens (PATs)

To upsert, delete, delete all, or update all PATs associated with a connector, use the following example commands:

```bash
# Upsert a PAT
ACTION=upsert_pat PAT_KEY="sample_key" PAT_VALUE="sample_value" path_to_script/connector_management.sh

# Delete a PAT
ACTION=delete_pat PAT_KEY="sample_key" path_to_script/connector_management.sh

# Delete all PATs
ACTION=delete_all_pats CONNECTOR_ID="sample_connector_id" path_to_script/connector_management.sh

# Update all PATs
ACTION=update_all_pats CONNECTOR_ID="sample_connector_id" PATS='{"user10":"pat_value"}' path_to_script/connector_management.sh

```

### Additional Help

For further assistance and detailed usage instructions, refer to the following command:

```bash
ACTION=help path_to_script/connector_management.sh
```

### Note

Ensure that the necessary prerequisites and action-specific arguments are provided when using the script to avoid any errors with the connector management operations.

This file outlines the basic usage of the provided bash script with examples for creating, updating, deleting, getting, and listing connectors, as well as managing Personal Access Tokens (PATs). It also includes a reminder to provide the necessary prerequisites and action-specific arguments when using the script. 
