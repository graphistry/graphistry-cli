# Airgapped Installation of Graphistry

You can run Graphistry in airgapped environments using the following steps:

0. Prerequisites
1. Download & extract Graphistry
2. Install the Graphistry CLI
3. Restart your bash environment
4. Configure Graphistry for offline
5. Load containers from the tarball
6. Launch!
7. Test



## 0. Prerequisites

* Graphistry (`*.tar.gz` file)
* Docker host setup for Nvidia:
  * Docker (RHEL): https://github.com/graphistry/graphistry-cli/blob/master/graphistry/bootstrap/rhel/20-docker.sh
  * CUDA 9.1 (RHEL): https://github.com/graphistry/graphistry-cli/blob/master/graphistry/bootstrap/rhel/30-CUDA.sh
  * Nivida-Docker 1 (RHEL): https://github.com/graphistry/graphistry-cli/blob/master/graphistry/bootstrap/rhel/40-nvidia-docker.sh  
  * *Alternatives*: Ubuntu, RHEL, CentOS -- https://github.com/graphistry/graphistry-cli/tree/master/graphistry/bootstrap
## 1. Download and extract Graphistry to ``~``

```
[ec2-user@ip- ~]$ curl "https://.../graphistry942-####.tar.gz" > graphistry942.tar.gz

[ec2-user@ip- ~]$ tar -xvvf graphistry942.tar.gz 
```

## 2. Install the Graphistry CLI with prepackaged dependencies

Comes with tarball (folder `graphistry-cli`) or from https://github.com/graphistry/graphistry-cli

```
[ec2-user@ip ~]$ cd ~/graphistry-cli/wheelhouse && sudo python3 -m wheel install * --force
[ec2-user@ip ~]$ cd ~/graphistry-cli && sudo python3 setup.py install
```

## 3. Restart your bash environment: log off and on again

```
[ec2-user@ip ~]$ exit
[ec2-user@ip ~]$ exit
$ ssh ec2-user@ip..o
```

## 4. Configure Graphistry for offline

You may leave everything blank except FQDN, HTTP Username, and HTTP Password:


```[ec2-user@ip- ~]$ graphistry
graphistry>> config_offline                                                                   ```

==>

Loading Config
[graphistry] Configure API key generation. [Hash algorithm is 'aes-256-cbc'.]
Hash Canary string (enter to autogenerate):                                                                                       
Your Secret string (enter to autogenerate):                                                                                       
[graphistry] Configure connectors
Your Elasticsearch Host, e.g., elk.company.com (enter to skip):                                                                   
Your Splunk Host, e.g., www.splunk.com (enter to skip):                                                                           
[graphistry] Configure networking
Your FQDN for this deployment, including protocol [e.g., http://graphistry.yourcompany.com]: http://my.website.com                                                                                                             
Your Internal IP Accept Whitelist (beyond typical RFC 1918), ex:["127.0.0.1", "10.*"]                                             
HTTP Ingress Username: admin                                                                                                      
HTTP Ingress Password: **                                                                                                         
AWS Access Key ID (enter to skip):                                                                                                
Saving Config
Wrote config: /home/ec2-user/.config/graphistry/config.json
```

## 5. Load containers from tarball

```
graphistry>> load                                                                             ```

==>

Loading Config
[localhost] local: docker load -i containers.tar
cd7100a72410: Loading layer [==================================================>]  4.403MB/4.403MB
90c4db1d5ef5: Loading layer [==================================================>]   14.8MB/14.8MB
...
faf7f7ff8bb6: Loading layer [==================================================>]  32.78MB/32.78MB
Loaded image: graphistry/s3cmd-postgres:latest
```

## 6. Launch!

```
graphistry>> launch                                                                           ```

==>
                                 
Loading Config
[localhost] local: sed -i 's!<VIZAPP_CONTAINER_NAME>!us.gcr.io/psychic-expanse-187412/graphistry/release/viz-app:942!g' deploy/launch.sh
...
Error: No such container: monolith-network-nginx
678f2ac85274f2d97453d019a1ede44bcad301d1bc61b6fdb798ae7ac25bc5c5
Error: No such container: monolith-network-splunk
SUCCESS.
Graphistry has been launched, and should be up and running.
SUCCESS.

Graphistry Launched. Please Browse to:
http://####.compute.amazonaws.com
```


## 7. Test

* Static assets: http://my.website.com
* GPUs: http://my.website.com/graph/graph.html?dataset=Facebook
* Uploads: Try a notebook upload pointing to the above server

See further tests at  https://github.com/graphistry/graphistry-cli
