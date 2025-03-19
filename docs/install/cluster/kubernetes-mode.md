# Multinode Deployment with Kubernetes

We can deploy a **Graphistry** cluster on any **Kubernetes (K8s)** distribution, making it versatile and adaptable to a variety of environments. Whether you're using a cloud-based solution like **Google Kubernetes Engine (GKE)**, **Amazon Elastic Kubernetes Service (EKS)**, or **Azure Kubernetes Service (AKS)**, or a local setup like **K3s** or **MicroK8s**, Graphistry can be deployed across any K8s platform.

As an example, you can follow the steps for deploying Graphistry on **K3s** or **Google Kubernetes Engine (GKE)** by referring to the [Graphistry Cluster setup guide](https://github.com/graphistry/graphistry-helm/tree/main/charts/values-overrides/examples/cluster). These steps are also a great reference for configuring your cluster on other Kubernetes distributions, including the setup of a **Distributed File System** for shared directories, such as using a **Network File System (NFS)** as an example.
