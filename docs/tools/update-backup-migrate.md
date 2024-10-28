# Update, Backup, and Migrate

Updates, backups, and migrations involve manipulating [configurations](../app-config/configure.md), local data, the global postgres data volume, and Graphistry install itself.

## Install multiple releases

### New servers vs. reuse

For simpler operation and improved uptime, we recommend creating new servers vs. upgrading existing ones. Likewise, only delete instances when a more recent backup is available.


### Folder structure

If reusing the same server, we recommend the following structure:

```
graphistry/releases/<VERSION_1>/
graphistry/releases/<VERSION_2>/
...
```

Each instance will include file `VERSION` and tag its images with that.


**If running concurrent versions of the same release:**

Edit `docker-compose.yml`'s top "`volumes:`" section to use a unique prefix

```yaml
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

### v2.25+:

Configuration and user data live in two places:

1. `data/`: Flatfiles safe for copying
2. The `postgres` container service: migrations handled via `pgdump`-based tooling

Graphistry internal configuration also lives in `.env` and `docker-compose.yml`. If you find yourself editing those, please let the Graphistry team know why so we can lessen the need for that.

### v2.24 and earlier

* **Local**:  Configuration and certain data is kept at the root of the installed release 
  * `.env`, `Caddyfile`, `.caddy`, `etc/ssl`, `.pivot-db`
  * Edits to `docker-compose.yml` (not recommeded)
* **Postgres**: Postgres volumes are managed by Docker
  * `docker volume ls | grep postgres` 
      * => `<version>_postgres_data`, `<version>_postgres_backups`
  * `sudo ls -al /var/lib/docker/volumes | grep postgres`
      * => `<version>_postgres_data`, `<version>_postgres_backups`

## Update an installation

NOTE: Check release version history for any special instructions.

Graphistry maintains backwards-compatibility around data. New versions automatically handle migration issues around database and file format data conversions. Administrators are responsible for backing up and loading in the old data. The exception is configuration files, which are still stabilizing in 2.X.

In practice, we recommend increasing service uptime and minimizing administrator effort by doing installs on fresh cloud instances. However, you can generally reuse the box.

### 2.25+

On your new Graphistry instance, run the `etc/scripts/migrate.sh` or `etc/scripts/migrate-local.sh` to copy your older install's state into the new install. The first script is for running between different servers and the second for different installs on the same server.

#### Steps

The rough recommended sequence is:

  * Test the new server primarily around GPU health
  * Run `migrate.sh` from the new server
  * Migration and backup information will be stored as `migration/` and `data.backup/`
  * Merge logic follows `rsync -a` merge rules for `data/` flatfiles and full replacement for `postgres` tables (users, ...)
  * The new instance will be restarted
  * Test the new server
  * When happy, switch DNS from the older instance to the new, and archive the old instance

An alternative approach that prioritizes integrity over uptime is to stop the old server at the beginning of the sequence.

#### migrate.sh: Work across distinct servers


Example: `migrate.sh` to go from AWS Marketplace instance `old.site.ngo` to `new.site.ngo`, with both using the same `key.pem`:

1. Launch the new server to initialize Postgres

2. From the new server, run 

```bash
ubuntu@new.site.ngo:~/graphistry$ KEY="~/.ssh/key.pem" FROM=ubuntu@old.site.ngo TO=ubuntu@new.site.ngo ./etc/scripts/migrate.sh
```

3. The script will start by testing the remote access; address ssh key sharing as need.


4. Upon success, test the new server, stop and archive the old one, and update the DNS for your users. If on AWS, see also the `update-dns.sh` script


#### migrate-local.sh: Work on the same server

Example: `migrate-local.sh` to add a new Graphistry version to an existing Graphistry server

1. Launch the new Docker instance to initialize Postgres. The caddy/nginx services will likely fail due to the web ports being already claimed: that is OK.

2.  From the new Docker instance folder, run

```
ubuntu@site.ngo:~/graphistry_new$ FROM_PATH="/var/old_graphistry" ./etc/scripts/migrate.sh
```

See the script header for additional options such as on `sudo` file permissions.

3. Test the new system works.

4. If on a memory-limited system, delete the version's docker container, volumes, images, and persisted files (`data/*`)



### 2.24 and older

Manually copy data/config files according to the [migration table](https://graphistry.zendesk.com/hc/en-us/articles/360035207474) . For edits to `.env`, separate them out to user file `custom.env`. See `migrate.sh` for handling postgres user table information.

## Backup & Migrate

Same as update. Running `migate.sh` on a new server will result in backups of `data/` flatfiles and the `postgres` service. Alternatively, you can manually copy `data/` and inspect `migrate.sh` for how to run `pgdump` with docker.

## Data Bridge

* Manually copy `connector.env` from the old bridge instance to the new
* In general, you can mix and match bridge/server combinations. Check the [version release histories](https://graphistry.zendesk.com/hc/en-us/articles/360033184174-Enterprise-Release-List-Downloads) for any violations of this rule.

