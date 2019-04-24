# AWS Marketplace Administration

The Graphistry marketplace instance is designed for secure and purely web-based use. However, command-line administration can be helpful. This document shares common marketplace tasks. See the surrounding docs for general CLI use. 

Contents:

1. **Log in**
1. **Docker**
1. **Install Jupyter packages**

## 1. Log in

Log in using the key you provided at instance start and the public IP/domain:

```ssh -i my_key.pem ubuntu@MY_IP_HERE```

##  2. Docker

Graphistry leverages `docker-compose` and `nvidia-docker2`. 

```
cd ~/graphistry
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

## 3. Install Jupyter packages

By default, Jupyter users do not have `sudo`, restricting them to user-level installation like `pip`. For system-level actions, such as for installing `golang` and other tools, you can create interactive `root` user sessions:


**Admin:**
```
ubuntu@ip-172-31-0-38:~/graphistry$ docker exec -t -u root graphistry_notebook_1 bash
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
