# Multinode Deployment with Docker Compose

This document offers step-by-step instructions for deploying **Graphistry** in a multinode environment using Docker Compose. In this architecture, a **leader** node handles dataset ingestion and manages the single PostgreSQL instance, while **follower** nodes can visualize graphs too using the shared datasets. Currently, only the leader node has permission to upload datasets and files (data ingestion), but future updates will allow follower nodes to also perform dataset and file uploads (data ingestion).

The leader and followers will share datasets using a **Distributed File System**, for example, using the Network File System (NFS) protocol. This setup allows all nodes to access the same dataset directory. This configuration ensures that **Graphistry** can be deployed across multiple machines, each with different GPU configuration profiles (some with more powerful GPUs, enabling multi-GPU on multinode setups), while keeping the dataset storage centralized and synchronized.


### Cluster Configuration Overview

1. **Leader Node**: Handles the ingestion of datasets, PostgreSQL write operations, and exposes the required PostgreSQL ports.
2. **Follower Nodes**: Connect to the PostgreSQL instance on the leader and can visualize graphs using the shared datasets. However, they do not have their own attached PostgreSQL instance.
3. **Shared Dataset**: All nodes will access the dataset directory using a **Distributed File System**. This ensures that the leader and followers use the same dataset, maintaining consistency across all nodes.
4. **PostgreSQL**: The PostgreSQL instance on the leader node is used by all nodes in the cluster for querying. The **Nexus** service, which provides the main dashboard for Graphistry, on the **Leader** node is responsible for managing access to the PostgreSQL database. The **Nexus** services on the **follower** nodes will use the PostgreSQL instance of the **Leader**.

### Configuration File: `cluster.env`

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

For this setup example, we will use the **Network File System (NFS)**, but any **Distributed File System** can be used to achieve the same goal. The file system must ensure that all nodes in the cluster can access the shared dataset directory. We will use **Ubuntu 22.04** on both the follower and leader nodes, with the follower having the IP address **192.168.18.8** and the leader **192.168.18.13**.

### Step 1: Configure the NFS Shared Directory

NFS will be used to share the dataset directory between nodes. Follow the steps below to set up NFS on both the leader and follower machines.

#### On the Leader Node (Main Machine)

1. **Create directories for PostgreSQL data and backups**:

    ```bash
    mkdir -p /mnt/data/shared/postgresql_data
    mkdir -p /mnt/data/shared/postgres_backups
    ```

    These directories will hold the PostgreSQL data and backups, which will be shared with follower nodes.

2. **Install NFS server**:

    On the leader node, install the NFS server software:

    ```bash
    sudo apt install nfs-kernel-server
    ```

    This will install the necessary software for serving NFS shares to the follower nodes.

3. **Configure NFS exports**:

    Edit the `/etc/exports` file to specify which directories should be shared and with what permissions. The following configuration allows the follower node (with IP `192.168.18.8`) to mount the shared directory with read/write permissions.

    ```bash
    sudo nano /etc/exports
    ```

    Add the following line to export the shared dataset directory:

    ```bash
    /mnt/data/shared/ 192.168.18.8(rw,sync,no_subtree_check)
    ```

    - `rw`: Allows read and write access.
    - `sync`: Ensures that changes are written to disk before responding to the client.
    - `no_subtree_check`: Disables subtree checking to improve performance.

4. **Export the NFS share** and restart the NFS server to apply the changes:

    ```bash
    sudo exportfs -a
    sudo systemctl restart nfs-kernel-server
    ```

5. **Disable the firewall** (if enabled) to ensure that NFS traffic is not blocked between nodes:

    Check the status of `ufw` (Uncomplicated Firewall):

    ```bash
    sudo ufw status
    ```

    If the firewall is enabled, disable it with:

    ```bash
    sudo ufw disable
    ```

    Alternatively, you can allow NFS traffic through the firewall, but disabling it is the easiest way to ensure communication between the nodes.

#### On the Follower Node (Secondary Machine)

1. **Create a directory to mount the NFS share**:

    ```bash
    mkdir -p /home/user1/mnt/data/shared/
    ```

    This is where the shared dataset will be mounted on the follower node.

2. **Install NFS client**:

    On the follower node, install the NFS client software to mount the NFS share:

    ```bash
    sudo apt install nfs-common
    ```

3. **Mount the shared NFS directory**:

    Mount the directory shared by the leader node to the local directory on the follower node:

    ```bash
    sudo mount -t nfs 192.168.18.13:/mnt/data/shared/ /home/user1/mnt/data/shared/
    ```

    - Replace `192.168.18.13` with the IP address of the leader node.
    - This command mounts the NFS share to `/home/user1/mnt/data/shared/` on the follower node.

4. **Verify the mount**:

    You can verify that the directory is mounted correctly using the following command:

    ```bash
    mount -l | grep /mnt/data/shared
    ```

    This should show an entry like:

    ```bash
    192.168.18.13:/mnt/data/shared on /home/user1/mnt/data/shared type nfs4 (rw,relatime,vers=4.2,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.18.8,local_lock=none,addr=192.168.18.13)
    ```

    This confirms that the NFS share is mounted and ready to use.

---

### Step 2: Docker Compose Setup

Now that the NFS share is set up, we can configure **Docker Compose** for **Graphistry**. Both the leader and follower nodes will utilize their own `cluster.env` file to define environment variables and configure the deployment.

1. **Ensure the correct configuration** for the `cluster.env` file. This file should contain the appropriate settings for **multinode mode**, **node type** (leader or follower), the **shared dataset directory**, and the **PostgreSQL connection**.

    Example of `cluster.env` for the leader node:

    ```bash
    ENABLE_CLUSTER_MODE=true
    NODE_TYPE=leader
    LOCAL_DATASET_CACHE_DIR=/mnt/data/shared/
    POSTGRES_HOST=postgres
    ```

    Example of `cluster.env` for a follower node:

    ```bash
    ENABLE_CLUSTER_MODE=true
    NODE_TYPE=follower
    LOCAL_DATASET_CACHE_DIR=/home/user1/mnt/data/shared/
    POSTGRES_HOST=192.168.18.13
    ```

2. **Start Docker Compose**:

    On the leader node, run the following command to start the Docker Compose instance:

    ```bash
    ./release up -d
    ```

    On each follower node, run the same command:

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

### Some utilities for NFS Management

- **Unmounting NFS** on the follower node:

    ```bash
    sudo umount /home/user1/mnt/data/shared/
    ```

- **Changing NFS permissions** (e.g., making the share read-only for the follower):

    1. Edit the `/etc/exports` file on the leader node:

        ```bash
        sudo nano /etc/exports
        ```

    2. Change the permissions from read-write to read-only:

        ```bash
        /mnt/data/shared/ 192.168.18.8(ro,sync,no_subtree_check)
        ```

    3. Apply the changes:

        ```bash
        sudo exportfs -ra
        sudo systemctl restart nfs-kernel-server
        ```

    4. On the follower node, remount the NFS share to apply the changes.

---

### Troubleshooting

- **Mounting Issues**: If the NFS mount does not appear or fails, verify the IP addresses and paths in the `/etc/exports` file on the leader node. Ensure that the follower node has access to the shared directory.
  
- **Firewall Issues**: Ensure that firewalls are disabled on both the leader and follower nodes or that the NFS ports are allowed. If the firewall is enabled, use `ufw` or `iptables` to allow NFS traffic.

- **Permission Issues**: If permission errors occur when accessing the shared directory, check the directory permissions on the leader node and ensure they are accessible by the user running Docker on the follower node.
