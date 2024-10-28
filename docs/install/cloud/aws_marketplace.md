# Graphistry in AWS Marketplace

Launching Graphistry in AWS Marketplace? [Get started](https://www.graphistry.com/blog/marketplace-tutorial) with the walkthrough tutorial and videos!

## Get it now!

1. Marketplace home: Click **Continue to subscribe**, **Continue to Configuration**
    - Do not *Configure contract* as that sets an annual prepay
2. Page **Configure this software**: 
    - **Region:** Select an AWS region with GPUs such as US East or Oregon (see [AWS availability of p3.* instances](https://ec2instances.info/))
    - You may need to request capacity for your account to run GPUs
    - Do not *Configure contract* as that sets an annual prepay
    - Click **Continue to launch**
3. Page **Launch this software**:
    - **EC2 Instance Type**: Pick g4dn.2xlarge+ (8 vCPU + 1 T4 GPU) / p3.2xlarge+ (8 vCPU + 1 V100 GPU) or larger as Graphistry/RAPIDS require a Pascal or later GPU. For single-user testing, you can pick g4dn.xlarge (4 vCPU + 1 T4 GPU).
    - **VPC Settings, Subnet Settings**: Pick something that your browser/client can access (http/https/ssh) and can speak to your DB
    - **Key Pair Settings**: Reuse or create a Key Pair so you can SSH to the commandline for administration
    - Click **Launch**
4. Go to the public IP in a browser and refresh until the login screen loads, login with `admin` / `i-YourAWSInstanceID`, and start graphing!


## Basic administration

* [Security: Enable auto-TLS and restrict network access](../../security/configure-security.md)
* [Create users](../../tools/user-creation.md)
* [Generate API keys](../../README.md) for individuals without accounts
* Turn server on-and-off via AWS Console via **stop** and **start**
* [Advanced configuration](../../app-config/configure.md)
* [Update, backup, and migrate](../../tools/update-backup-migrate.md)
  * To simplify administration and limit downtime, we recommend creating a new Marketplace instance, copying data snapshots to it and loading it in, and switching DNS to the new instance only when tested

## Common marketpace administration

The Graphistry marketplace instance is designed for secure web-based use and administration. However, command-line administration can be helpful. This document shares common marketplace tasks. See the [main docs](https://github.com/graphistry/graphistry-cli) for general CLI use. 

Contents:

1. **Recommended configuration**
1. **Solve GPU availability errors**
1. **Command-line Login**
1. **Docker**
1. **Install Python packages**
1. **Install native packages**
1. **Marketplace FAQ**


### 1. Recommended configuration
 
* Use a regular AWS account as it is safer than [AWS Root account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html)
* [Associate your AWS instance with an Elastic IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-eips-associating) or a domain 
* [Setup TLS](../../app-config/configure.md), potentially through an AWS Load Balancer (ALB)
* In restricted environments, constrain networking to a safelist, e.g., VPN, and optional, [change logging drivers](https://docs.docker.com/config/containers/logging/configure/) to stop Graphistry from recieving maintenace logs. See [recommended port restrictions](../../security/configure-security.md)
  * You can limit instance traffic to VPC-internal, such as not associating a public IP: SSH via a bastion server, and route all public HTTP/HTTPS through an AWS Load Balancer (ALB), including aan AWS Web Application Firewall (WAF)
* If expecting many uploads, attach a managed disk. Contact Graphistry staff for automation assistance.

### 2. Solve GPU availability errors

Upon trying to launch, Amazon may fail with an error about no available GPUs for two reasons:

* Lack of GPU availability in the current region. In this case, try another valid GPU type, or launching in another region. For example, Virginia => Oregon. Keeping the GPU close to your users is a good idea to minimize latency.

* Insufficient account quota. In this case, the error should also contain a link to increase your quota. Request `p3.2` (and above), and 1-2 for a primary region and 1-2 for a secondary region.


### 3. Command-line Login

Log in using the key configured at AWS instance start and your instance's public IP/domain:

```ssh -i my_key.pem ubuntu@MY_PUBLIC_IP_HERE```

Many `ssh` clients may require you to first run `chmod 400 my_key.pem` or `chmod 644 my_key.pem` before running the above.

### 4. Docker

Graphistry leverages `docker-compose` and the AWS Marketplace AMI preconfigures the `nvidia` runtime for `docker`.

```bash
cd ~/graphistry
sudo docker compose ps
```

=>

```
            Name                           Command                   State                              Ports                       
------------------------------------------------------------------------------------------------------------------------------------
compose_caddy_1                 /bin/parent caddy --conf / ...   Up               2015/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp
compose_forge-etl-python_1      /tini -- /entrypoints/etl- ...   Up (unhealthy)   8080/tcp                                          
compose_forge-etl_1             /tini -- /entrypoints/pm2. ...   Up (healthy)     8080/tcp                                          
compose_nexus_1                 /entrypoint /bin/bash -c b ...   Up               8000/tcp                                          
compose_nginx_1                 nginx -g daemon off;             Up               80/tcp, 8080/tcp                                  
compose_notebook_1              /tini -g -- /bin/bash -c s ...   Up               8080/tcp                                          
compose_pivot_1                 /tini -- /entrypoints/stre ...   Up (healthy)     8080/tcp                                          
compose_postgres_1              docker-entrypoint.sh postgres    Up               5432/tcp, 8080/tcp                                
compose_redis_1                 docker-entrypoint.sh redis ...   Up               6379/tcp, 8080/tcp                                
compose_streamgl-gpu_1          /tini -- /entrypoints/fast ...   Up (healthy)     8080/tcp                                          
compose_streamgl-sessions_1     /tini -- /entrypoints/fast ...   Up (healthy)     8080/tcp                                          
compose_streamgl-vgraph-etl_1   /tini -- /entrypoints/fast ...   Up (healthy)     8080/tcp                                          
compose_streamgl-viz_1          /tini -- /entrypoints/stre ...   Up               8080/tcp   
 
```

*Note*: Precise set of containers changes across versions

### 5. Install Python packages

If you see `wheel` errors, you may need to run `pip install wheel` and restart your Jupyter kernel.

### 6. Install native packages

By default, Jupyter users do not have `sudo`, restricting them to user-level installation like `pip`. For system-level actions, such as for installing `golang` and other tools, you can create interactive `root` user sessions by logging into the Jupyter Docker container:


**Admin:**

Note that `sudo` is unnecessary within the container:

```
ubuntu@ip-172-31-0-38:~/graphistry$ docker exec -it -u root graphistry_notebook_1 bash
root@d4afa8b7ced5:/home/graphistry# apt update 
root@d4afa8b7ced5:/home/graphistry# apt install golang
root@d4afa8b7ced5:/home/graphistry# source activate base && conda install pyarrow
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


### 7. Marketplace FAQ

#### No site loads or there is an Nginx 404 error

Wait a few minutes for the system to finish starting. If the problem persists for more than 5-10min, log in, run `docker ps`, and for each failing service, restart it. If problems persist further, please report the results of `docker logs <service>` to the Graphistry support team and we will help out.

#### I lost my admin account

See the `reset` command in the main README. Requires SSH'ing in, and will delete all users, but not data.

#### I want to log into the server

See section `login`

---

See [general installation](https://github.com/graphistry/graphistry-cli) for further information.
