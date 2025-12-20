# Scripts Reference

This page provides a comprehensive reference for all admin and operator scripts available in your Graphistry installation.

## Overview

Scripts are located in `./etc/scripts/` relative to your Graphistry installation directory. Most scripts are designed to be run from the Graphistry root directory.

```bash
cd /home/ubuntu/graphistry  # or your install path
./etc/scripts/<script_name>.sh
```

## GPU & Configuration

### `gpu-config-wizard.sh`

Interactive GPU configuration generator with 140+ hardware presets for cloud and on-prem environments.

See [GPU Configuration Wizard](gpu-config-wizard.md) for complete documentation including:
- Usage examples and command-line options
- All hardware presets (DGX, AWS, Azure, GCP, OCI, Lambda, CoreWeave)
- Worker replication model
- Generated environment variables

**Quick start:**
```bash
# Interactive mode
./etc/scripts/gpu-config-wizard.sh

# Export to custom.env
./etc/scripts/gpu-config-wizard.sh -E ./data/config/custom.env

# List available presets
./etc/scripts/gpu-config-wizard.sh -l
```

### `test-gpu.sh`

Verify GPU environment setup and RAPIDS capability. Referenced in [Testing an Install](../install/testing-an-install.md#7-quick-testing-and-test-gpu).

**Usage:**
```bash
./etc/scripts/test-gpu.sh
```

**Tests performed:**
- CPU Docker installation (`docker run hello-world`)
- Host GPU availability (`nvidia-smi`)
- NVIDIA Docker runtime (`--gpus=all` and `--runtime=nvidia`)
- Docker GPU defaults (used by `./graphistry` wrapper)
- RAPIDS compute capability (cuDF sum operation)

**Environment variables:**
| Variable | Description |
|----------|-------------|
| `GRAPHISTRY_VERSION` | Override version tag (default: reads from `VERSION` file) |
| `CUDA_SHORT_VERSION` | Override CUDA version (default: `11.8`) |

### `cred-gen.sh`

Generate security credentials and encryption keys for Graphistry services.

**Usage:**
```bash
# Generate and append to custom.env
./etc/scripts/cred-gen.sh >> ./data/config/custom.env
```

**Generated variables:**
| Variable | Purpose |
|----------|---------|
| `AUTH_LDAP_BIND_PASSWORD` | LDAP authentication binding |
| `DJANGO_SECRET_KEY` | Django session security |
| `GRAPHISTRY_NEXUS_ENCRYPTION_KEYS` | Data encryption |
| `GRAPHISTRY_NEXUS_SIGNING_KEY` | Request signing |
| `GRAPHISTRY_NEXUS_SIGNING_SALT` | Signing salt |

See also [Connector Management - Find or generate signing keys](../app-config/connector-management.md#find-or-generate-signing-keys) for usage in connector configuration.

## Backup & Migration

### `backup.sh` / `restore.sh`

Backup and restore Graphistry data to remote blob storage (AWS S3, Azure Blob Storage, Google Cloud Storage) using [restic](https://restic.net/).

See [Backup and Restore Instructions](backup-and-restore.md) for complete documentation including:
- Cloud provider configuration (AWS, Azure, GCP)
- Environment variables reference
- Scheduling backups with cron
- Dry-run and tagging options

**Quick start:**
```bash
# Backup (after configuring RESTIC_* env vars)
./etc/scripts/backup.sh

# Restore
./etc/scripts/restore.sh

# Dry run
DRY_RUN=True ./etc/scripts/backup.sh
```

### `migrate.sh` / `migrate-local-db.sh`

Server-to-server and local database migration scripts.

See [Update, Backup, and Migrate](update-backup-migrate.md) for complete documentation including:
- Migration between servers
- Same-server version upgrades
- Data and PostgreSQL migration

**Quick start:**
```bash
# Remote migration (from new server)
KEY="~/.ssh/key.pem" FROM=ubuntu@old.site.ngo TO=ubuntu@new.site.ngo ./etc/scripts/migrate.sh

# Local migration
FROM_PATH="/var/old_graphistry" ./etc/scripts/migrate-local-db.sh
```

**Environment variables (`migrate.sh`):**
| Variable | Default | Description |
|----------|---------|-------------|
| `FROM` | - | Source server (user@host) |
| `TO` | - | Target server (user@host) |
| `FROM_PATH` | `/home/ubuntu/graphistry` | Source install directory |
| `TO_PATH` | `/home/ubuntu/graphistry` | Target install directory |
| `KEY` | - | SSH private key path |
| `TO_PATH_TEMP` | `${TO_PATH}/migration` | Temporary migration directory |

## Account & Connector Management

### `connector_management.sh`

CRUD operations for Graphistry-managed data connectors (e.g., Databricks).

See [Managed Connector CLI](../app-config/connector-management.md) for complete documentation including:
- Prerequisites and environment setup
- All actions (create, update, delete, get, list)
- PAT management for Databricks
- Keyjson configuration examples

**Quick start:**
```bash
# List connectors
ACTION=list ./etc/scripts/connector_management.sh

# Create connector
ACTION=create ORG_NAME=my_org CONNECTOR_NAME="MyConnector" \
  CONNECTOR_DETAIL='{"host": "example.com"}' \
  ./etc/scripts/connector_management.sh

# Get help
ACTION=help ./etc/scripts/connector_management.sh
```

### `account-list.sh`

List all user accounts and their activity status.

**Usage:**
```bash
./etc/scripts/account-list.sh
```

Wrapper for `CMD_NAME=list_accounts ./etc/scripts/nexus-command.sh`.

### `account-transfer-data.sh`

Transfer data ownership between user accounts.

**Usage:**
```bash
FROM_USER=olduser TO_USER=newuser ./etc/scripts/account-transfer-data.sh
```

**Environment variables:**
| Variable | Description |
|----------|-------------|
| `FROM_USER` | Source username |
| `TO_USER` | Destination username |

### `account-sso-verify.sh`

Verify SSO configuration and test authentication flow.

**Usage:**
```bash
./etc/scripts/account-sso-verify.sh
```

### `manage-pat.sh`

Manage personal access tokens for user accounts.

**Usage:**
```bash
# List PATs
ACTION=list USER=username ./etc/scripts/manage-pat.sh

# Create PAT
ACTION=create USER=username NAME="my-token" ./etc/scripts/manage-pat.sh

# Revoke PAT
ACTION=revoke USER=username TOKEN_ID=abc123 ./etc/scripts/manage-pat.sh
```

### `nexus-command.sh`

Execute Django management commands inside the Nexus container.

**Usage:**
```bash
CMD_NAME=<command_name> ./etc/scripts/nexus-command.sh
```

**Available commands:**
| Command | Description |
|---------|-------------|
| `list_accounts` | List all user accounts |
| `create_user` | Create a new user |
| `change_password` | Change user password |
| `shell` | Django interactive shell |

**Example:**
```bash
# List accounts
CMD_NAME=list_accounts ./etc/scripts/nexus-command.sh

# Django shell
CMD_NAME=shell ./etc/scripts/nexus-command.sh
```

## Database Operations

### `copy-db-local.sh`

Create a local PostgreSQL database backup using `pg_dump`.

**Usage:**
```bash
./etc/scripts/copy-db-local.sh
```

**Output:** Creates a SQL dump in the current directory.

See also [Backup and Restore - Warning](backup-and-restore.md#overview) for notes on manually exporting PostgreSQL.

### `load-db-local.sh`

Load a local PostgreSQL database backup.

**Usage:**
```bash
DUMP_FILE=backup.sql ./etc/scripts/load-db-local.sh
```

### `sql-backup-remote.sh`

Create PostgreSQL backup on a remote server.

**Usage:**
```bash
REMOTE_HOST=user@server ./etc/scripts/sql-backup-remote.sh
```

## Monitoring & Diagnostics

### `health_checks.sh`

Monitor service health status across all Graphistry containers.

**Usage:**
```bash
./etc/scripts/health_checks.sh
```

**Output:** Health status for each service with pass/fail indicators.

See also [Health Check REST APIs](https://hub.graphistry.com/docs/api/2/rest/health/) for programmatic health checks.

### `docker-stats-csv.sh`

Export Docker container resource statistics to CSV format.

**Usage:**
```bash
./etc/scripts/docker-stats-csv.sh > stats.csv
```

**Output columns:** Container ID, Name, CPU %, Memory Usage/Limit, Memory %, Network I/O, Block I/O, PIDs

### `dump_docker_logs.sh`

Dump logs from all Graphistry containers to files.

**Usage:**
```bash
./etc/scripts/dump_docker_logs.sh
```

**Output:** Creates log files in `./logs/` directory.

### `disk.sh`

Monitor disk usage for Graphistry data directories.

**Usage:**
```bash
./etc/scripts/disk.sh
```

**Output:** Disk usage summary for data directories, Docker volumes, and system partitions.

### `restart-nvidia-driver.sh`

Restart the NVIDIA driver (requires stopping GPU containers first).

**Usage:**
```bash
# Stop GPU services first
./graphistry stop forge-etl-python streamgl-gpu dask-cuda-worker

# Restart driver
sudo ./etc/scripts/restart-nvidia-driver.sh

# Restart services
./graphistry up -d
```

### `toggle-nvidia-docker.sh`

Toggle between NVIDIA Docker runtime configurations.

**Usage:**
```bash
./etc/scripts/toggle-nvidia-docker.sh
```

## Cloud & Service Setup

### `graphistry-service-account.sh`

Create a Graphistry service account for automation and API access.

**Usage:**
```bash
./etc/scripts/graphistry-service-account.sh
```

### `graphistry-service-account.aws.sh`

Create an AWS-specific service account with IAM permissions.

**Usage:**
```bash
./etc/scripts/graphistry-service-account.aws.sh
```

### `init.aws.sh`

Initialize AWS-specific configuration for Graphistry deployment.

**Usage:**
```bash
./etc/scripts/init.aws.sh
```

### `create-louie-oauth-app.sh`

Create OAuth application configuration for Louie integration.

**Usage:**
```bash
./etc/scripts/create-louie-oauth-app.sh
```

## REST API Examples

The `etc/scripts/rest/` directory contains lightweight bash scripts demonstrating REST API usage. These serve as both testing tools and implementation examples.

See [REST API Documentation](https://hub.graphistry.com/docs/api/) for full API reference.

### Authentication

| Script | Description |
|--------|-------------|
| `jwt-token-create.sh` | Create JWT authentication token |
| `session.sh` | Start authenticated session |
| `sessions.sh` | List active sessions |

**Example - Create JWT token:**
```bash
GRAPHISTRY_USERNAME=admin GRAPHISTRY_PASSWORD=pass \
  GRAPHISTRY_BASE_PATH=https://my.graphistry.com \
  ./etc/scripts/rest/jwt-token-create.sh
```

### Account Management

| Script | Description |
|--------|-------------|
| `admin-account-create.sh` | Create admin account |
| `user-create.sh` | Create standard user |
| `user-list.sh` | List all users |

### Data Operations

| Script | Description |
|--------|-------------|
| `dataset-create.sh` | Create new dataset |
| `dataset-list.sh` | List datasets |
| `file-upload.sh` | Upload file to dataset |
| `file-list.sh` | List files in dataset |

### Sharing & Permissions

| Script | Description |
|--------|-------------|
| `share-link.sh` | Generate shareable visualization link |
| `permission-check-read.sh` | Check read permissions |
| `permission-check-write.sh` | Check write permissions |
| `permission-grant.sh` | Grant permissions to user |

### Autocomplete & Search

| Script | Description |
|--------|-------------|
| `auto-complete-nodes.sh` | Node autocomplete search |
| `auto-complete-edges.sh` | Edge autocomplete search |
| `search-nodes.sh` | Search nodes by property |

### Common Environment Variables

All REST API scripts use these environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `GRAPHISTRY_BASE_PATH` | Yes | Server URL (e.g., `https://my.graphistry.com`) |
| `GRAPHISTRY_USERNAME` | Yes | Admin username |
| `GRAPHISTRY_PASSWORD` | Yes | Admin password |
| `JWT_TOKEN` | No | Pre-generated JWT token (skips auth) |

## Quick Reference

| Category | Scripts | Documentation |
|----------|---------|---------------|
| GPU Setup | `gpu-config-wizard.sh`, `test-gpu.sh` | [GPU Config Wizard](gpu-config-wizard.md), [Testing](../install/testing-an-install.md) |
| Security | `cred-gen.sh` | [Connector Management](../app-config/connector-management.md) |
| Backup | `backup.sh`, `restore.sh` | [Backup & Restore](backup-and-restore.md) |
| Migration | `migrate.sh`, `migrate-local-db.sh` | [Update, Backup, Migrate](update-backup-migrate.md) |
| Connectors | `connector_management.sh` | [Connector Management](../app-config/connector-management.md) |
| Accounts | `account-list.sh`, `nexus-command.sh` | This page |
| Database | `copy-db-local.sh`, `load-db-local.sh` | This page |
| Monitoring | `health_checks.sh`, `docker-stats-csv.sh` | This page |
| REST API | `etc/scripts/rest/*` | [REST API Docs](https://hub.graphistry.com/docs/api/) |
