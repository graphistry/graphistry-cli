# Graphistry in Azure Marketplace

You can now securely run Graphistry in your private Azure account with one click by launching [Graphistry in Azure Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/graphistry.graphistry-core-2-24-9)!

See also [Azure Marketplace private offers for Graphistry Core BYOL](azure_marketplace_private_offer.md)

## Get it now!

1. Click **create** (vs. **Start with a pre-set configuration**)
1. Fill  most VM settings as usual: Resource group, VM Name, and User + SSH Key / Password
    - **Region**: Pick a GPU-capable region in which you have GPU quota (see below), such as East US and West US 2
    - **Size**: Select **NC4as_T4_v3**, **NC6s_v2**, **NC6s_v3** (and *not* v1 series of *NC6s*) or bigger within the same families
      - If the first time using GPUs, you may need to make a quota request, which generally takes 1-2 days
    - If asked, publicly expose (for incoming connections) `http` (80), `https` (443), `ssh` (22), and potentially unconfigured `streamlit` (8501)
1. Click **Review and create** and then **Create**
1. Go to the public IP, refresh the page until it has fully loaded, create the first user (= admin) account, and start graphing!

Please [reach out](https://www.graphistry.com/support) to our team if we can help along the way.

## Basic administration

* [Security: Enable auto-TLS and restrict network access](configure-security.md)
* [Create users](user-creation.md)
* [Generate API keys](../README.md) for individuals without accounts
* Turn server on-and-off in the Azure Console via **stop** and **start**
* [Advanced configuration](configure.md)
* [Update, backup, and migrate](update-backup-migrate.md)
  * To simplify administration and limit downtime, we recommend creating a new Marketplace instance, copying data snapshots to it and loading it in, and switching DNS to the new instance only when tested

## Common marketpace administration

The Graphistry marketplace instance is designed for secure web-based use and administration. However, command-line administration can be helpful. This document shares common marketplace tasks. See the [main docs](https://github.com/graphistry/graphistry-cli) for general CLI use. 

Contents:

1. **Azure special notes**
1. **Recommended configuration**
1. **Solve GPU availability errors**
1. **Command-line Login**
1. **Docker**
1. **Install Python packages**
1. **Install native packages**
1. **Marketplace FAQ**


### 1. Azure special notes

* Pick an NC4as_T4_v3, NCv2-series, or NCv3-series GPU, such as an NC6s v2, from an [Azure GPU-capable region near you](https://azure.microsoft.com/en-us/global-infrastructure/services/) 
* Install path: `/var/graphistry`
* If many uploads are expected, you may benefit from attaching a managed disk; contact Graphistry staff for automation scripts

### 2. Recommended configuration

* Public ports:
  * HTTP (80), HTTPS (443), SSH (22), and optionally StreamLit (8501)
    * You can lock these down further at any time, e.g., only open 22 when using
  * In restricted environments, constrain networking to a a safelist, e.g., VPN, and optional, [change logging drivers](https://docs.docker.com/config/containers/logging/configure/) to stop Graphistry from recieving maintenace logs
* Assign a static IP or DNS entry to your Graphistry instance 
* [Setup TLS](configure.md) and [restrict ports](configure-security.md)


### 3. Solve GPU availability errors

Upon trying to pick a VM size or launching, Azure may fail for several reasons:

* Insufficient account quota. Solve by requesting increased GPU / vCPU core capacity in your target launch region and extra regions for dev and contention periods. From your Azure Portal, go to  `? (Help)` -> `Help + support` -> `New support request` -> `Service and subscription (Quotas)` ([link](https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade/overview)).  Request quota for multiple `NC4as_T4_v3`, `NC6s_v2`, `NC6_v3`s or bigger in the same family for your intended [regions that have them](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=virtual-machines). We recommend at least 3x-4x quota: production, staging, test1, test2. Later, you may want more for scaling experiments.

* Lack of GPU availability in the current region. In this case, try another valid GPU type in the current region, or launch in another region. Keeping the GPU close to your users is a good idea to minimize latency.


### 4. Command-line Login

Logging in is configured at Azure instance start and uses your instance's public IP/domain, custom username, and choice of password or SSH key:

```ssh -i my_key.pem my_username@MY_PUBLIC_IP_HERE```

Many `ssh` clients may require you to first run `chmod 400 my_key.pem` or `chmod 644 my_key.pem` before running the above.

### 5. Docker

Graphistry leverages `docker-compose` and the Azure image preconfigures the `nvidia` runtime for `docker`.  Note that Graphistry in Azure requires `sudo`.

```
cd /var/graphistry
docker-compose ps
```

=>

```
               Name                             Command                  State                        Ports                  
-----------------------------------------------------------------------------------------------------------------------------
graphistry_celerybeat_1              /entrypoint bash /start-ce ...   Up             8080/tcp                                
graphistry_celeryworker_1            /entrypoint bash /start-ce ...   Up             8080/tcp                                
graphistry_forge-etl_1               /tini -- /entrypoints/fast ...   Up (healthy)   8080/tcp                                
graphistry_nexus_1                   /entrypoint /bin/sh -c bas ...   Up             8080/tcp                                
graphistry_nginx_1                   nginx -g daemon off;             Up             0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp
graphistry_notebook_1                /bin/sh -c graphistry_api_ ...   Up             8080/tcp                                
graphistry_postgres_1                docker-entrypoint.sh postgres    Up             5432/tcp, 8080/tcp                      
graphistry_redis_1                   docker-entrypoint.sh redis ...   Up             6379/tcp, 8080/tcp                      
graphistry_streamgl-datasets_1       /tini -- /entrypoints/fast ...   Up (healthy)   8080/tcp                                
graphistry_streamgl-gpu_1            /tini -- /entrypoints/fast ...   Up (healthy)   8080/tcp                                
graphistry_streamgl-sessions_1       /tini -- /entrypoints/fast ...   Up (healthy)   8080/tcp                                
graphistry_streamgl-svg-snapshot_1   /tini -- /entrypoints/fast ...   Up (healthy)   8080/tcp                                
graphistry_streamgl-vgraph-etl_1     /tini -- /entrypoints/fast ...   Up (healthy)   8080/tcp                                
graphistry_streamgl-viz_1            /tini -- /entrypoints/stre ...   Up             8080/tcp   
```

*Note*: Precise set of containers changes across versions

### 6. Install Python packages

If you see `wheel` errors, you may need to run `pip install wheel` and restart your Jupyter kernel.

### 7. Install native packages

By default, Jupyter users do not have `sudo`, restricting them to user-level installation like `pip`. For system-level actions, such as for installing `golang` and other tools, you can create interactive `root` user sessions by logging into the Jupyter Docker container:


**Admin:**

Note that `sudo` is unnecessary:

```
ubuntu@ip-172-31-0-38:~/graphistry$ docker exec -it -u root graphistry_notebook_1 bash
root@d4afa8b7ced5:/home/graphistry# apt update 
root@d4afa8b7ced5:/home/graphistry# apt install golang
```

**User:**
```
ubuntu@ip-172-31-0-38:~/graphistry$ docker exec -it  graphistry_notebook_1 bash
graphistry@d4afa8b7ced5:~$ go version
```
=>
```
go version go1.10.4 linux/amd64
```


### 8. Marketplace FAQ

#### No site loads or there is an Nginx 404 error

Wait a few minutes for the system to finish starting. If the problem persists for more than 5-10min, log in, run `docker ps`, and for each failing service, restart it. If problems persist further, please report the results of `docker logs <service>` to the Graphistry support team and we will help out.

#### I lost my admin account

See the `reset` command in the main README. Requires logging in, and will delete all users, but no data.

#### I want to log into the server

See section `login`

#### I want to use a private VM

Private marketplace: See section [Azure Marketplace Privacy Offer: Launching Graphistry Core BYOL](azure_marketplace_private_offer.md)

Private docker: Check Azure instructins for VM sizing and Docker instructions for manual installation.

---

See [general installation](https://github.com/graphistry/graphistry-cli) for further information.
