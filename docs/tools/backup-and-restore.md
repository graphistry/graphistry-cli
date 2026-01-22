# Backup and Restore Instructions

## Overview

Backup and restore scripts are provided that will backup your Graphistry environment to remote blob storage (AWS S3, Azure Blob Storage, or Google Cloud Storage). Graphistry uses [restic](https://restic.net/), a fast and secure incremental backup utility for remote blob storage. More details can be found in the [restic documentation](https://restic.readthedocs.io/en/stable/index.html).

<br>

> **Warning**  
> On restore, the existing Postgres database and data directory are irrevocably lost. If you think you may need the Postgres database and/or data directory on the restore server, either run `backup.sh` from the restore server or manually copy the data directory and export from the Postgres database.  
>  
> See `${FROM_PATH}/etc/scripts/copy-db-local.sh` for details on manually exporting Postgres.

<br>

### [Configuration](#configuration)
### [Backup](#backup)
### [Restore](#restore)
### [Scheduling Backups](#scheduling-backups)

<br>

## Configuration

The following environment variables are required depending on the cloud provider.

### AWS

See the [restic Amazon S3 documentation](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#amazon-s3).

We recommend adding these to `~/.bashrc` or `~/.profile`, then restarting the shell or sourcing the file:

```bash
export AWS_ACCESS_KEY_ID=<MY_ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<MY_SECRET_ACCESS_KEY>

export RESTIC_REPOSITORY=s3:s3.amazonaws.com/<bucket_name>/<path>
export RESTIC_PASSWORD=<restic_repo_password>
````

### Azure

See the [restic Azure Blob Storage documentation](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#microsoft-azure-blob-storage).

```bash
export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_KEY=<SECRET_KEY>

# or

export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_SAS=<SAS_TOKEN>

export RESTIC_REPOSITORY=azure:<storage_account>:/<path>
export RESTIC_PASSWORD=<restic_repo_password>
```

### Google Cloud Storage

See the [restic Google Cloud Storage documentation](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#google-cloud-storage).

You may also use the [Google Cloud CLI](https://cloud.google.com/sdk/gcloud):

```bash
project=<gcp_project_name>
bucket=gs://<bucket_name>/

GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gs-secret-restic-key.json

service_acct=$(gcloud --project=${project} iam service-accounts list --format=json \
  | jq -r '.[] | select(.displayName=="Compute Engine default service account") | .email')

gcloud iam service-accounts keys create ${GOOGLE_APPLICATION_CREDENTIALS} \
  --iam-account=${service_acct}

gsutil iam ch serviceAccount:${service_acct}:objectCreator,objectViewer,objectAdmin ${bucket}
```

Add the following to your shell environment:

```bash
export GOOGLE_PROJECT_ID=123123123123
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gs-secret-restic-key.json

export RESTIC_REPOSITORY=gs:<bucket_name>:/<bucket_path>
export RESTIC_PASSWORD=<restic_repo_password>
```

<br>

## Backup

Backup configuration options:

| Variable          | Default if unset        | Description                             |
| ----------------- | ----------------------- | --------------------------------------- |
| FROM_PATH         | /home/ubuntu/graphistry | Graphistry install directory            |
| DATA_DIR          | ${FROM_PATH}/data       | Override if data directory is symlinked |
| LOCAL_SUDO_DISK   | sudo                    | Set to empty string to disable sudo     |
| LOCAL_SUDO_DOCKER | sudo                    | Set to empty string to disable sudo     |
| DRY_RUN           | False                   | Dry run only                            |
| RESTIC_TAGS       | "graphistry"            | Space-separated list of snapshot tags   |

<br>

1. Define `RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, and provider-specific credentials as described in the [Configuration](#configuration) section.
2. SSH into the Graphistry server:

   ```bash
   ssh -i </path/to/private_key> ubuntu@<IP_addr>
   ```
3. Change to the scripts directory:

```bash
# AWS
cd /home/ubuntu/graphistry/compose/etc/scripts

# Azure
cd /var/graphistry/compose/etc/scripts
```

4. Run the backup script:

```bash
# AWS
./backup.sh

# Azure
FROM_PATH=/var/graphistry ./backup.sh
```

### Additional examples

```bash
# Dry run
DRY_RUN=True ./backup.sh

# Add snapshot tags
RESTIC_TAGS="server_1 dev nightly" ./backup.sh

# Override data directory if symlinked
DATA_DIR=/mnt/data ./backup.sh
```

<br>

## Restore

Restore configuration options:

| Variable          | Default if unset        | Description                             |
| ----------------- | ----------------------- | --------------------------------------- |
| TO_PATH           | /home/ubuntu/graphistry | Graphistry install directory            |
| DATA_DIR          | ${FROM_PATH}/data       | Override if data directory is symlinked |
| LOCAL_SUDO_DISK   | sudo                    | Set to empty string to disable sudo     |
| LOCAL_SUDO_DOCKER | sudo                    | Set to empty string to disable sudo     |
| DRY_RUN           | False                   | Dry run only                            |
| RESTIC_TAGS       | "graphistry"            | Space-separated list of snapshot tags   |

<br>

1. SSH into the Graphistry server.
2. Change to the scripts directory:

```bash
# AWS
cd /home/ubuntu/graphistry/compose/etc/scripts

# Azure
cd /var/graphistry/compose/etc/scripts
```

3. Run the restore script:

```bash
# AWS
./restore.sh
```

```bash
# Azure
TO_PATH=/var/graphistry ./restore.sh
```

<br>

## Scheduling Backups

Any scheduler can be used. Below are cron examples.

```bash
crontab -l
crontab -e
```

### AWS cron examples

```bash
# Daily
0 0 * * * /home/ubuntu/graphistry/compose/etc/scripts/backup.sh

# Weekly
0 0 * * 0 /home/ubuntu/graphistry/compose/etc/scripts/backup.sh
```

### Azure cron examples

```bash
# Daily
0 0 * * * TO_PATH=/var/graphistry /var/graphistry/compose/etc/scripts/backup.sh

# Weekly
0 0 * * 0 TO_PATH=/var/graphistry /var/graphistry/compose/etc/scripts/backup.sh
```

### Wrapper script example

```bash
#!/bin/bash

export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_KEY=<SECRET_KEY>

export RESTIC_REPOSITORY=azure:<storage_account>:/<path>
export RESTIC_PASSWORD=<restic_repo_password>

export FROM_PATH=/var/graphistry
export RESTIC_TAGS="server2 prod nightly"

${FROM_PATH}/compose/etc/scripts/backup.sh
```

Make executable:

```bash
chmod +x ~/scripts/my_backup_script.sh
```

Add to crontab:

```bash
0 0 * * * ~/scripts/my_backup_script.sh
```
