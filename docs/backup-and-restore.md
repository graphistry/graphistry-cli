# Backup and Restore Instructions: 

### Overview

Backup and restore scripts are provided that will backup your graphistry environment to remote blob storage (AWS s3, Azure Blob Storage or Google Cloud Storage). Graphistry uses [restic](https://restic.net/) backup utility which provides fast and secure incremental backups to remote blob storage. More details can be found in the [restic documentation](https://restic.readthedocs.io/en/stable/index.html).

<br>

> **Warning** 
> On a restore, the existing postgres database and data directory are irrevocably lost. If think you may need the postgres and/or data directory on the restore server, either run backup.sh from the restore server or manually copy the data directory and export from the postgres database. See `${FROM_PATH}/etc/scripts/copy-db-local.sh` for details on manually exporting postgres. 


<br> 

### Configuration

The following environment variables are required for depending on the cloud provider: 

[**AWS:**](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#amazon-s3)

We recommend adding these to ~/.bashrc or ~/.profile and re-starting the shell or sourcing the file to pick up the changes: 

```
export AWS_ACCESS_KEY_ID=<MY_ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<MY_SECRET_ACCESS_KEY>

export RESTIC_REPOSITORY=azure:<storage_account>:/<path>
export RESTIC_PASSWORD=<restic_repo_password>

```

[**Azure:**](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#microsoft-azure-blob-storage)

We recommend adding these to ~/.bashrc or ~/.profile and re-starting the shell or sourcing the file to pick up the changes: 

```
# we recommend adding these to ~/.bashrc or ~/.profile 

export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_KEY=<SECRET_KEY>

# or

export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_SAS=<SAS_TOKEN>

# and 

export RESTIC_REPOSITORY=s3:s3.amazonaws.com/<bucket_name>/<bucket_path>
export RESTIC_PASSWORD=<restic_repo_password>

```

[**Google Cloud Storage Authentication**](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#google-cloud-storage): 

Restic supports using a Service Account to access the storage bucket, see instructions in the link above, or you can follow these steps from the [Google CLI](https://cloud.google.com/sdk/gcloud): 

```
# define the project: 
project=<gcp_project_name>

# define the bucket: 
bucket=gs://<bucket_name>/

# define the default compute service account credential file path: 
GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gs-secret-restic-key.json

# get the default service account email address:
service_acct=$(gcloud --project=${project} iam service-accounts list --format=json | jq -r '.[] | select(.displayName=="Compute Engine default service account")| .email')

# get the service account key file:
gcloud iam service-accounts keys create ${GOOGLE_APPLICATION_CREDENTIALS} --iam-account=${service_acct}

# grant the default service account required permissions to access the bucket: 
gsutil iam ch serviceAccount:${service_account}:objectCreator,objectViewer,objectAdmin ${bucket}

```

We recommend adding these to ~/.bashrc or ~/.profile and re-starting the shell or sourcing the file to pick up the changes: 

```

export GOOGLE_PROJECT_ID=123123123123
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gs-secret-restic-key.json

export RESTIC_REPOSITORY=gs:<bucket_name:/<bucket_path>
export RESTIC_PASSWORD=<restic_repo_password>

```


## Backup

backup config options: 

| variable          | default if unset                      | description                    |
|-------------------|---------------------------------------|--------------------------------|
| FROM_PATH         | /home/ubuntu/graphistry               | graphistry install dir         |
| DATA_DIR          | ${FROM_PATH}/data                     | override if symlinked data dir |
| LOCAL_SUDO_DISK   | sudo                                  | set to empty str to override   |
| LOCAL_SUDO_DOCKER | sudo                                  | set to empty str to override   |
| DRY_RUN           | False                                 | dry run only                   |
| RESTIC_TAGS       | "graphistry"                          | space separated list of tags   |

<br><br>

1. ssh into the graphistry server e.g. `ssh -i </path/to/private_key> ubuntu@IP_addr`

2. cd to the scripts directory in <GRAPHISTRY_HOME>

```
# AWS: 
cd /home/ubuntu/graphistry/compose/etc/scripts

# Azure 
cd /var/graphistry/compose/etc/scripts

```

3. Run the backup script: 

```
# AWS
./backup.sh

# Azure
FROM_PATH=/var/graphistry/ ./backup.sh 
```


### Restore

| variable          | default if unset                      | description                    |
|-------------------|---------------------------------------|--------------------------------|
| TO_PATH           | /home/ubuntu/graphistry               | graphistry install dir         |
| DATA_DIR          | ${FROM_PATH}/data                     | override if symlinked data dir |
| LOCAL_SUDO_DISK   | sudo                                  | set to empty str to override   |
| LOCAL_SUDO_DOCKER | sudo                                  | set to empty str to override   |
| DRY_RUN           | False                                 | dry run only                   |
| RESTIC_TAGS       | "graphistry"                          | space separated list of tags   |

<br><br>

1. ssh into the graphistry server e.g. `ssh -i </path/to/private_key> ubuntu@IP_addr`

2. cd to the scripts directory in <GRAPHISTRY_HOME>

```
# AWS: 
cd /home/ubuntu/graphistry/compose/etc/scripts

# Azure 
cd /var/graphistry/compose/etc/scripts

```

3. Run the backup script: 


```
# AWS

./restore.sh
```

<br> 

```
# Azure

TO_PATH=/var/graphistry/ ./restore.sh 
```



### scheduling nightly or weekly backups with cron: 

```
# list your current crontab entries: 

crontab -l 
```

<br> 

```
# edit your contrab

crontab -e 
```

<br> 

AWS: 
```
# add the following line to run backup either daily: 

0 0 * * * /home/ubuntu/graphistry/compose/etc/scripts/backup.sh 

# add the following line to run backup either weekly: 

0 0 * * 0 /home/ubuntu/graphistry/compose/etc/scripts/backup.sh
```

<br> 

Azure: 

```
# add the following line to run backup either daily: 

0 0 * * * TO_PATH=/var/graphistry/ /var/graphistry/compose/etc/scripts/backup.sh 

# add the following line to run backup either weekly: 

0 0 * * 0 TO_PATH=/var/graphistry/ /var/graphistry/compose/etc/scripts/backup.sh
```



