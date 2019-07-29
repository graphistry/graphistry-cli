# Update, Backup, and Migrate

Updates, backups, and migrations involve manipulating [configurations](configure.md), local data, the global postgres data volume, and Graphistry install itself.

## Install multiple releases

**We recommend the following folder structure:**

```
graphistry/releases/v1.3.2/
graphistry/releases/v2.10.5/
...
```

**If running concurrent versions of the same release:**

Edit `docker-compose.yml`'s top "`volumes:`" section to use a unique prefix

```
volumes:
  ...
  postgres_data:
    name:  v2_10_5_MY_COPY_2_postgres_data
```

Launch under a unique name using `-p`:  

```
docker-compose -p my_unique_name up -d
```

## The config and data files

* **Local**:  Configuration and certain data is kept at the root of the installed release 
  * `.env`, `Caddyfile`, `.caddy`, `etc/ssl`, `.pivot-db`
  * Edits to `docker-compose.yml` (not recommeded)
* **Postgres**: Postgres volumes are managed by Docker
  * `docker volume ls | grep postgres` 
      * => `<version>_postgres_data`, `<version>_postgres_backups`
  * `sudo ls -al /var/lib/docker/volumes | grep postgres`
      * => `<version>_postgres_data`, `<version>_postgres_backups`

## Update

NOTE: Check release version history for any special instructions.

Graphistry maintains backwards-compatibility around data. New versions automatically handle migration issues around database and file format data conversions. Administrators are responsible for backing up and loading in the old data.

In practice, we recommend increasing service uptime nad minimizing administrator effort by doing installs on fresh cloud instances. However, you can generally reuse the box.

 doing new installs on new instances, and instead m


* Put new release in a new folder
* Snapshsot the old instance, and ideally, while it is stopped
  * `old_release $ docker-compose stop`
  * Copy local config and data files into the new install folder
  * Copy the Postgres data: see below
* 	Run the usual installation and launch procedure: `docker load -i containers.tar`, ...

### Special case: Postgres   


**Option A: Postgres-managed data migration:**

The safest approach is to use `pgdump` to backup and `psql` to restore. See `.env` for `postgres` user/password/db configurations:


```
old_release $ docker-compose exec postgres  /usr/bin/pg_dump  -U graphistry graphistry | gzip -9 > backup.sql.gz
 
new_release $ docker-compose docker exec postgres psql -U graphistry graphistry < backup.sql
```


**Option B: Direct file system copy:**
  
If the underlying `postgres` container and your system environment have not changed, you may be able to simply copy the volumes:
  
```
cp -rp /var/lib/docker/volumes/<version_1>_postgres_data /var/lib/docker/volumes/<version_2>_postgres_data
cp -rp /var/lib/docker/volumes/<version_1>_postgres_backups /var/lib/docker/volumes/<version_2>_postgres_backups
```

See the [Docker-managed instructions](https://docs.docker.com/v17.03/engine/tutorials/dockervolumes/#backup-restore-or-migrate-data-volumes) to do the same.


## Backup & Migrate

Same as update.