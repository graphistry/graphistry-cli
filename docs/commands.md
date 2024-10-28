# Top commands

Graphistry supports advanced command-line administration via standard `docker compose`, `.yml` / `.env` files, and `caddy` reverse-proxy configuration.

## Login to server

| Image | Command |
|--: |:-- |
| **AWS** | `ssh -i [your_key].pem ubuntu@[your_public_ip]` |
| **Azure** | `ssh -i [your_key].pem [your_user]@[your_public_ip]` <br> `ssh [your_user]@[your_public_ip]` (pwd-based) |
| **Google** | `gcloud compute [your_instance] ssh` |
| **On-prem / BYOL** | Contact your admin |

## CLI commands

All likely require `sudo`. Run from where your `docker-compose.yml` file is located:  `/home/ubuntu/graphistry` (AWS), `/var/graphistry` (Azure), or `/var/graphistry/<releases>/<version>` (recommended on-prem).

|  TASK	| COMMAND 	| NOTES 	|
|--: |:---	|:---	|
| **Install** 	| `docker load -i containers.tar.gz` 	| Install the `containers.tar.gz` Graphistry release from the current folder. You may need to first run `tar -xvvf my-graphistry-release.tar.gz`.	|
| **Start <br>interactive** 	| `docker compose up` 	| Starts Graphistry, close with ctrl-c 	|
| **Start <br>daemon** 	| `docker compose up -d` 	| Starts Graphistry as background process 	|
| **Start <br>namespaced (concurrent)** 	| `docker compose -p my_unique_namespace up` 	| Starts Graphistry in a specific namespace. Enables running multiple independent instances of Graphistry. NOTE: Must modify Caddy service in `docker-compose.yml` to use non-conflicting public ports, and likewise change global volumes to be independent. 	|
| **Stop** 	| `docker compose stop` 	| Stops Graphistry 	|
| **Restart (soft)** 	| `docker restart <CONTAINER>` 	| Soft restart. May also need to restart service `nginx`. 	|
| **Restart (hard)** 	| `docker up -d --force-recreate --no-deps <CONTAINER>` 	|  Restart with fresh state. May also need to restart service `nginx`.	|
| **Reset**     | `docker compose down -v && docker compose up -d` | Stop Graphistry, remove all internal state (including the user account database!), and start fresh .  |
| **Status** 	 | `docker compose ps`, `docker ps`, and `docker status` 	|  Status: Uptime, healthchecks, ...	|
| **GPU Status** | `nvidia-smi` | See GPU processes, compute/memory consumption, and driver.  Ex: `watch -n 1.5 nvidia-smi`. Also, `docker run --rm -it nvidia/cuda:11.5.0-base-ubuntu20.04 nvidia-smi` for in-container test. |
| **1.0 API Key** | docker compose exec streamgl-vgraph-etl curl "http://0.0.0.0:8080/api/internal/provision?text=MYUSERNAME" 	|  Generates API key for a developer or notebook user	(1.0 API is deprecated)|
| **Logs** 	|  `docker compose logs <CONTAINER>` 	|  Ex: Watch all logs, starting with the 20 most recent lines:  `docker compose logs -f -t --tail=20 forge-etl-python`	. You likely need to switch Docker to use the local json logging driver by  deleting the two default managed Splunk log driver options in `/etc/docker/daemon.json` and then restarting the `docker` daemon (see below). |
| **Create Users** | Use Admin Panel (see [Create Users](tools/user-creation.md)) or `etc/scripts/rest` |
| **Restart Docker Daemon** | `sudo service docker restart` | Use when changing `/etc/docker/daemon.json`, ... |
| **Jupyter shell**| `docker exec -it -u root graphistry_notebook_1 bash` then `source activate rapids` | Use for admin tasks like global package installs |