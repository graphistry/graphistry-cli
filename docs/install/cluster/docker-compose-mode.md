# Multinode Deployment with Docker Compose

This document provides step-by-step instructions for deploying **Graphistry** in a multinode environment using Docker Compose.

## Configuration File: `cluster.env`

The configuration for multinode deployment is managed through the environment file `cluster.env`. This file will vary depending on whether the node is a **leader** or a **follower** in the deployment. It defines key settings such as the node type (`leader` or `follower`), the shared dataset directory, and the single shared PostgreSQL connection.

```bash
# Graphistry Cluster Configuration
#
# https://github.com/graphistry/graphistry-cli/blob/master/docs/cluster.md


# ENABLE_CLUSTER_MODE: true | false (default false)
# All nodes will use the same LOCAL_DATASET_CACHE_DIR and postgres instance (the leader one).
ENABLE_CLUSTER_MODE=false

# NODE_TYPE: leader | follower (default leader)
# If ENABLE_CLUSTER_MODE=true and NODE_TYPE=leader it exposes the postgres ports to the host (LAN).
# If ENABLE_CLUSTER_MODE=true and NODE_TYPE=follower the follower node won't start the postgres service.
NODE_TYPE=leader

# LOCAL_DATASET_CACHE_DIR=/host/path/ (default: /opt/graphistry/data)
# This environment variable can be defined in other configuration files,
# but the value here will take precedence and override those settings (e.g., custom.env).
# Examples:
# When NODE_TYPE=leader, LOCAL_DATASET_CACHE_DIR may point to an NFS path for local data storage.
# When NODE_TYPE=follower, LOCAL_DATASET_CACHE_DIR may point to a mount path that references the leader's network file system (e.g. the NFS path).
LOCAL_DATASET_CACHE_DIR=/opt/graphistry/data

# POSTGRES_HOST=ip | host_url (default: postgres)
# If NODE_TYPE=follower it will use this env var to setup the postgres remote conn string.
# This environment variable can be defined in other configuration files,
# but the value here will take precedence and override those settings (e.g., custom.env).
# Examples:
# When NODE_TYPE=leader, POSTGRES_HOST may be postgres (.i.e. the internal postgres service that Graphistry deploys).
# When NODE_TYPE=follower, POSTGRES_HOST may point to the host where the leader is running.
POSTGRES_HOST=postgres
```

## Setup Instructions

For this setup example, we will use the **Network File System (NFS)**, but any **Distributed File System** can be used to achieve the same goal. The file system must ensure that all nodes in the cluster can access the shared dataset directory. We will use **Ubuntu 22.04** on both the follower and leader nodes, with the follower having the IP address **192.168.0.20** and the leader **192.168.0.10**.

Additionally, ensure that the **firewall** on both the leader and follower nodes is configured to allow **NFS** traffic on the necessary ports (e.g., 2049), enabling seamless communication between the nodes.

### Step 1: Configure the NFS Shared Directory

NFS will be used to share the dataset directory between nodes. Follow the steps below to set up NFS on both the leader and follower machines.

#### On the Leader Node (Main Machine)

1. **Install NFS server**:

    On the leader node, install the NFS server software:

    ```bash
    sudo apt install nfs-kernel-server
    ```

    This will install the necessary software for serving NFS shares to the follower nodes.

2. **Create directories for PostgreSQL and shared data**:

    ```bash
    # These directories will store PostgreSQL data and backups
    mkdir -p /mnt/data/shared/postgresql_data
    mkdir -p /mnt/data/shared/postgres_backups

    # Create the shared directory
    mkdir -p /mnt/data/shared/uploads /mnt/data/shared/files /mnt/data/shared/datasets
    ```

3. **Set appropriate permissions on the shared directory**:

    To ensure the shared directory has the correct permissions and can be written to by NFS clients, it’s important to verify and configure access properly. The user is responsible for ensuring that the shared directory has the necessary permissions to allow remote follower nodes to read, write, and modify files as needed. For instance, you may need to apply the following changes to make sure the shared directory is accessible by NFS clients:

    ```bash
    # Set permissions to allow full access (read, write, execute) for all users
    sudo chmod -R 777 /mnt/data/shared/

    # Change ownership to 'nobody:nogroup' for NFS access
    sudo chown -R nobody:nogroup /mnt/data/shared/
    ```

    This will allow all users and processes (including the remote follower instances) to read and write to the shared directory, ensuring they can ingest datasets and files. You can adjust these permissions later based on your security requirements.

    *Notice: The following shared directory permissions are provided as an example. Please ensure the settings align with your security policies.*

4. **Configure NFS exports**:

    Edit the `/etc/exports` file to specify which directories should be shared and with what permissions. The following configuration allows the follower node (with IP `192.168.0.20`) to mount the shared directory with read/write permissions.

    ```bash
    sudo nano /etc/exports
    ```

    Add the following line to export the shared dataset directory:

    ```bash
    /mnt/data/shared/ 192.168.0.20(rw,sync,no_subtree_check,no_root_squash)
    ```

    - `rw`: Allows read and write access.
    - `sync`: Ensures that changes are written to disk before responding to the client.
    - `no_subtree_check`: Disables subtree checking to improve performance.
    - `no_root_squash`: Retains root access for the client’s root user on the shared directory, which can be necessary for certain tasks but should be used with caution due to the elevated permissions.

    *Notice: The following NFS configuration is provided as an example. Please ensure the settings align with your security policies.*

5. **Export the NFS share** and restart the NFS server to apply the changes:

    ```bash
    sudo exportfs -a
    sudo systemctl restart nfs-kernel-server
    ```

#### On the Follower Node (Secondary Machine)

1. **Install NFS client**:

    On the follower node, install the NFS client software to mount the NFS share:

    ```bash
    sudo apt install nfs-common
    ```

2. **Create a directory to mount the NFS share**:

    ```bash
    mkdir -p /home/user1/mnt/data/shared/
    ```

    This is where the shared dataset will be mounted on the follower node.

3. **Mount the shared NFS directory**:

    Mount the directory shared by the leader node to the local directory on the follower node:

    ```bash
    sudo mount -t nfs 192.168.0.10:/mnt/data/shared/ /home/user1/mnt/data/shared/
    ```

    - Replace `192.168.0.10` with the IP address of the leader node.
    - This command mounts the NFS share to `/home/user1/mnt/data/shared/` on the follower node.

4. **Verify the mount**:

    You can verify that the directory is mounted correctly using the following command:

    ```bash
    mount -l | grep /mnt/data/shared
    ```

    This should show an entry like:

    ```bash
    192.168.0.10:/mnt/data/shared on /home/user1/mnt/data/shared type nfs4 (rw,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.0.20,local_lock=none,addr=192.168.0.10)
    ```

    This confirms that the NFS share is mounted and ready to use.

### Step 2: Docker Compose Setup

Now that the NFS share is set up, we can configure **Docker Compose** for **Graphistry**. Both the leader and follower nodes will utilize their own `cluster.env` file to define environment variables and configure the deployment.

1. **Ensure the correct configuration** for the `cluster.env` file. This file should contain the appropriate settings for **multinode mode**, **node type** (leader or follower), the **shared dataset directory**, and the **PostgreSQL connection**.

    Example of `cluster.env` for the **leader** node:

    ```bash
    ENABLE_CLUSTER_MODE=true
    NODE_TYPE=leader
    LOCAL_DATASET_CACHE_DIR=/mnt/data/shared/
    POSTGRES_HOST=postgres
    ```

    Example of `cluster.env` for a **follower** node:

    ```bash
    ENABLE_CLUSTER_MODE=true
    NODE_TYPE=follower
    LOCAL_DATASET_CACHE_DIR=/home/user1/mnt/data/shared/
    POSTGRES_HOST=192.168.0.10
    ```

2. **Start Docker Compose**:

    On the leader and on each follower node, run the following command to start the Docker Compose instance:

    ```bash
    ./release up -d
    ```

    This will start the **Graphistry** containers across all nodes, enabling them to connect to the PostgreSQL instance on the leader node. If the leader is not ready, the followers will wait for the PostgreSQL service to become available. Once the leader is online, the followers will resume their operations, ensuring a smooth startup. For example, follower nodes will log messages like:


    ```javascript
    compose-forge-etl-python-1       | 2025-01-08T00:37:51.432950416Z Waiting for PostgreSQL to become available...
    compose-streamgl-viz-1           | 2025-01-08T00:37:51.433181258Z Waiting for PostgreSQL to become available...
    compose-pivot-1                  | 2025-01-08T00:37:51.820240166Z Waiting for PostgreSQL to become available...
    compose-forge-etl-1              | 2025-01-08T00:37:51.820134913Z Waiting for PostgreSQL to become available...
    ```

### Step 3: Verifying the Setup

After the deployment, ensure that the following checks are in place:

1. **Leader Node**:
    - The leader node should be running the PostgreSQL instance.
    - The dataset ingestion feature should be available, and you can upload datasets to the shared NFS directory.
    - The leader should be exposed to the host for PostgreSQL connections.

2. **Follower Nodes**:
    - Followers should be able to access the dataset via the NFS mount and create graphs.
    - Followers should connect to the PostgreSQL instance on the leader node but will not be able to perform write operations (ingestion).

To verify the operation, you can check the logs of each node using:

```bash
./release logs
```

## Usage

Once the deployment is complete, you can use the leader node to upload datasets, files and perform other data ingestion tasks. The `VISUALIZE FILES (BETA)` feature in Graphistry can be used to upload graph datasets and files. Additionally, you can use the Graphistry Clients (such as `pygraphistry`, `graphistry-js`) or the `REST API` to interact with the data (all of them pointing to the IP/address of the leader):

* PyGraphistry: https://github.com/graphistry/pygraphistry
* Graphistry JS: https://github.com/graphistry/graphistry-js
* REST API: API Docs: https://hub.graphistry.com/docs/api

For example, you can interact with any node from **PyGraphistry** like this:

```python
import graphistry
server_address = "192.168.0.10" # using the leader
# or using the follower (server_address=192.168.0.20)
graphistry.register(api=3, protocol="http", server=server_address, username="user1", password="password1")
...
```

Once the upload is finished, these datasets and files will be available on all follower nodes and the leader for visualization. Each graph session on any instance is independent by default. This means that visualizations on the leader and follower nodes are isolated from one another. However, collaborative features will be enabled if users are pointed to the same instance (leader or follower). In this case, multiple users can interact with the same visualization, sharing insights and collaborating in real-time. Additionally, both the leader and follower nodes will have the ability to delete shared datasets and files using the Nexus dashboard, ensuring that data management can be handled across the entire deployment.

This setup provides flexibility for both individual exploration and team collaboration, while ensuring that the data and visualizations remain synchronized across the deployment. It also provides high availability and better scalability for Graphistry deployments.

## Troubleshooting

- **Mounting Issues**: If the NFS mount does not appear or fails, verify the IP addresses and paths in the `/etc/exports` file on the leader node. Ensure that the follower node has access to the shared directory.
  
- **Firewall Issues**: Ensure that the firewall on both the leader and follower nodes is properly configured to allow NFS traffic. Use tools like `ufw` or `iptables` to open the necessary NFS ports (e.g., 2049) based on your installation.

- **Permission Issues**: If permission errors occur when accessing the shared directory, check the directory permissions on the leader node and ensure they are accessible by the user running Docker on the follower node.
