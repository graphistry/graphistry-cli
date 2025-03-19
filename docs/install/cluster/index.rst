Cluster Installation
========================

.. toctree::
  :maxdepth: 1

  docker-compose-mode
  kubernetes-mode


Multinode Deployment Overview
------------------------

**Note**: *This deployment configuration is currently **experimental** and subject to future updates.*


In this installation, both the **Leader** and **Follower** nodes can ingest datasets and files, with all nodes accessing the same **PostgreSQL** instance on the **Leader** node. As a result, **Follower** nodes can also perform data uploads, ensuring that both **Leader** and **Follower** nodes have equal access to dataset ingestion and visualization.

The leader and followers will share datasets using a **Distributed File System**, for example, using the **Network File System (NFS)** protocol. This setup allows all nodes to access the same dataset directory. This configuration ensures that **Graphistry** can be deployed across multiple machines, each with different **GPU** configuration profiles (some with more powerful GPUs, enabling **multi-GPU** on multinode setups), while keeping the dataset storage centralized and synchronized.

Cluster Configuration Overview
^^^^^^^^^^^^^^^^^^^^^^^^

1. **Leader Node**:  
   Handles the ingestion of datasets, PostgreSQL write operations, and exposes the required PostgreSQL ports.

2. **Follower Nodes**:  
   Connect to the PostgreSQL instance on the leader and can visualize graphs using the shared datasets. However, they do not have their own attached PostgreSQL instance.

3. **Shared Data**:  
   All nodes will access the same **datasets directory** using a **Distributed File System**. This ensures that the leader and followers use the same dataset, maintaining consistency across all nodes.

4. **PostgreSQL**:  
   The PostgreSQL instance on the **Leader** node is used by all nodes for querying. The **Nexus** service on the **Leader** manages access to the database, while **Follower** nodes also use the **Leader’s** PostgreSQL instance. Both **Leader** and **Follower** nodes can perform actions like user sign-ups and settings modifications through their own **Nexus** dashboards, with changes applied system-wide for consistency across all nodes.

5. **Redis**:  
   The Redis instance on the **Leader** will be used by all **Nexus** and **forge-etl-python** services on the **Follower** nodes. However, for **StreamGL** visualizations, each **Graphistry** instance will have its own Redis instance.
