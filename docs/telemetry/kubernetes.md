# Kubernetes Telemetry

## Overview
To deploy OpenTelemetry services for Graphistry in a Kubernetes environment, you will need to configure the system using Helm values.  For comprehensive documentation on deploying Graphistry with Helm, refer to the official documentation at [Graphistry Helm Documentation](https://graphistry-helm.readthedocs.io/).  Additionally, you can explore the open-source Helm project for Graphistry on GitHub at [Graphistry Helm GitHub](https://github.com/graphistry/graphistry-helm).

## Telemetry Deployment Modes
Graphistry services export telemetry data (metrics and traces) using the OpenTelemetry standard.  In Kubernetes, the telemetry data is pushed to the OpenTelemetry Collector (otel-collector), which forwards it to observability tools such as Prometheus, Jaeger, Grafana Cloud, etc.

Kubernetes supports two primary modes of telemetry deployment, similar to Docker Compose:

### Forwarding to External Services (Cloud Mode)
When the Helm value `telemetryStack.OTEL_CLOUD_MODE` is `true`, telemetry data is forwarded to external services like `Grafana Cloud`, similar to [Docker Compose’s Forwarding to External Services mode](./docker-compose.md#forwarding-to-external-services).

### Using Packaged Observability Tools
When the Helm value `telemetryStack.OTEL_CLOUD_MODE` is `false`, the stack bundled with Graphistry (Prometheus, Jaeger, Grafana) is deployed, and telemetry data is exported to these tools, similar to [Docker Compose’s Using Packaged Observability Tools mode](docker-compose.md#using-packaged-observability-tools).

### Hybrid Mode
You can also configure a Hybrid Mode, combining both local tools and external services.  This requires custom Helm chart adjustments to forward data to both local and external observability services.  See [Docker Compose’s Hybrid Mode](docker-compose.md#hybrid-mode) for more information.

## Prerequisites

Before deploying OpenTelemetry services for Graphistry on Kubernetes, ensure you have the following prerequisites in place:

1. **Kubernetes Cluster**: You must have access to a running Kubernetes cluster.
2. **Helm**: Helm is the package manager for Kubernetes that simplifies the deployment and management of applications.
3. **Graphistry Helm Project**: You must have the `graphistry-helm` project cloned or downloaded to your local machine.  This project contains the necessary Helm charts and configurations for deploying Graphistry services with Kubernetes.  You can find the project and instructions in the official [Graphistry Helm GitHub repository](https://github.com/graphistry/graphistry-helm).
4. **Access to Required Resources**: Ensure you have the necessary permissions to deploy applications to the Kubernetes cluster.  You may need appropriate access rights to the cloud provider's Kubernetes resources or administrative permissions for your self-hosted Kubernetes environment.

## Helm Values for OpenTelemetry in Kubernetes

To deploy OpenTelemetry for Graphistry in a Kubernetes environment, you'll need to configure the Helm deployment with specific values. These values are typically defined in a `values.yaml` file, which will replace the Docker Compose configuration in your setup.

The following is an example of the configuration you would include in your `values.yaml` file to deploy OpenTelemetry services within Kubernetes:

```yaml
global:  ## global settings for all charts
  ENABLE_OPEN_TELEMETRY: false

  # Graphistry Telemetry values and environment variables for observability tools
  # can be set like helm upgrade -i chart_name --name release_name \
  #--set stENVPublic.LOG_LEVEL="FOO"
  # Telemetry documentation:
  # https://github.com/graphistry/graphistry-cli/blob/master/docs/tools/telemetry.md#kubernetes-deployment
  telemetryStack:
    OTEL_CLOUD_MODE: false   # false: deploy our stack: jaeger, prometheus, grafana etc.; else fill OTEL_COLLECTOR_OTLP_HTTP_ENDPOINT and credentials bellow
    openTelemetryCollector:
      image: "otel/opentelemetry-collector-contrib:0.87.0"
      # Settings for cloud mode (when OTEL_CLOUD_MODE: true)
      OTEL_COLLECTOR_OTLP_HTTP_ENDPOINT: ""   # e.g. Grafana OTLP HTTP endpoint for Graphistry Hub https://otlp-gateway-prod-us-east-0.grafana.net/otlp
      OTEL_COLLECTOR_OTLP_USERNAME: ""   # e.g. Grafana Cloud Instance ID for OTLP
      OTEL_COLLECTOR_OTLP_PASSWORD: ""   # e.g. Grafana Cloud API Token for OTLP
      # Settings for cluster mode (when graphistry-helm.global.ENABLE_CLUSTER_MODE: true)
      LEADER_OTEL_EXPORTER_OTLP_ENDPOINT: "" # All followers's collectors will export to this leader collector, and from there the telemetry data will be exported to Grafana, Prometheus, Jaeger, etc; e.g. "otel-collector.graphistry1.svc.cluster.local:4317"

    grafana:
      image: "grafana/grafana:11.0.0"
      GF_SERVER_ROOT_URL: "/grafana"
      GF_SERVER_SERVE_FROM_SUB_PATH: "true"
    dcgmExporter:
      image: "nvcr.io/nvidia/k8s/dcgm-exporter:3.3.5-3.4.1-ubuntu22.04"
      DCGM_EXPORTER_CLOCK_EVENTS_COUNT_WINDOW_SIZE: 1000  # milliseconds
    jaeger:
      image: "jaegertracing/all-in-one:1.50.0"
      OTEL_EXPORTER_JAEGER_ENDPOINT: "jaeger:4317"
    nodeExporter:
      image: "prom/node-exporter:v1.8.2"
    prometheus:
      image: "prom/prometheus:v2.47.2"
```

## Configuration Overview

1. **`global`**: This section in the `values.yaml` file is used to define values that are accessible across all charts within the parent-child hierarchy.  Both the parent chart (e.g., `charts/graphistry-helm`) and its child charts (e.g., `charts/graphistry-helm/charts/telemetry`) can reference these global values using `.Values.global.<value_name>`, providing a unified configuration across the deployment.

2. **`telemetryStack`**: This section defines environment variables that control the OpenTelemetry configuration in Kubernetes. These variables replicate the settings that were originally defined in the Docker Compose setup.

3. **`global.ENABLE_OPEN_TELEMETRY`**: Set to `true` to enable the OpenTelemetry stack within the Kubernetes environment. This will ensure that telemetry data is collected and processed by the relevant tools in your stack.

4. **`telemetryStack.OTEL_CLOUD_MODE`**:
  - When set to `false`, the internal observability stack (`Jaeger`, `Prometheus`, `Grafana`, `NVIDIA DCGM Exporter` and `Node Exporter`) is deployed locally within your Kubernetes cluster.  So, setting it to `false` is similar to [using packaged observability tools](./docker-compose.md#using-packaged-observability-tools) within the Kubernetes environment.
  - When set to `true`, telemetry data is forwarded to external services, such as Grafana Cloud or other OTLP-compatible services.  So, setting this to `true` is equivalent to [forwarding telemetry to external services](./docker-compose.md#forwarding-to-external-services).

5. **`telemetryStack.openTelemetryCollector.OTEL_COLLECTOR_OTLP_HTTP_ENDPOINT`**, **`telemetryStack.openTelemetryCollector.OTEL_COLLECTOR_OTLP_USERNAME`**, and **`telemetryStack.openTelemetryCollector.OTEL_COLLECTOR_OTLP_PASSWORD`**: These fields are required only if `OTEL_CLOUD_MODE` is set to `true`. They provide the necessary connection details (such as the endpoint, username, and password) for forwarding telemetry data to external services like Grafana Cloud or other OTLP-compatible services.

6. **`telemetryStack.openTelemetryCollector.LEADER_OTEL_EXPORTER_OTLP_ENDPOINT`**: This field is used by all follower collectors when `global.ENABLE_CLUSTER_MODE` is set to `true`.  In this case, all follower collectors will export their telemetry data to the leader's collector, which will then export the data to Grafana, Prometheus, Jaeger, etc. For example: `"otel-collector.graphistry1.svc.cluster.local:4317"`.  See the guide on [Configuring Telemetry for a Graphistry Cluster on Kubernetes](https://github.com/graphistry/graphistry-helm/tree/main/charts/values-overrides/examples/cluster#configuring-telemetry-for-graphistry-cluster-on-kubernetes).

7. **`telemetryStack.grafana.GF_SERVER_ROOT_URL`** and **`telemetryStack.grafana.GF_SERVER_SERVE_FROM_SUB_PATH`**: These settings are used to configure Grafana, especially when it's deployed behind a reverse proxy or using an ingress controller.
  - **`telemetryStack.grafana.GF_SERVER_ROOT_URL`** defines the root URL for accessing Grafana (e.g., `/grafana`).
  - **`telemetryStack.grafana.GF_SERVER_SERVE_FROM_SUB_PATH`** should be set to `true` if Grafana is accessed from a sub-path (e.g., `/grafana`) behind a reverse proxy or ingress.

8. **`telemetryStack.dcgmExporter.DCGM_EXPORTER_CLOCK_EVENTS_COUNT_WINDOW_SIZE`**: This environment variable controls the GPU metric sampling resolution for `dcgm-exporter`, which exports GPU telemetry to `Prometheus`. It defines the window size (in milliseconds) for counting clock events on the GPU.
  - A smaller value (e.g., 500) results in higher-resolution telemetry with more frequent GPU metric updates.
  - A larger value (e.g., 2000) reduces the data rate but lowers monitoring overhead.
This setting applies regardless of `OTEL_CLOUD_MODE` and affects both local and cloud-based telemetry setups.

9. **`telemetryStack.*.image`**: These values allow to change the image versions of the observability tools.

## Caddyfile - reverse proxy set up
In Kubernetes, you can customize the Caddy configuration to expose or route telemetry data to different observability endpoints, offering flexibility for your deployment.  By default, the Kubernetes setup includes ingress configurations for `Prometheus`, `Jaeger`, and `Grafana` dashboards.  However, if you need more control over the routing or wish to modify the reverse proxy settings, you can refer to the [Docker Compose section for guidance on configuring Caddy](docker-compose.md#caddyfile---reverse-proxy-set-up).  To modify the Caddy configuration in Kubernetes, such as on [GKE (Google Kubernetes Engine)](https://github.com/graphistry/graphistry-helm/tree/main/charts/values-overrides/examples/gke), follow these steps:
1. Edit the [Caddy ConfigMap](https://github.com/graphistry/graphistry-helm/blob/main/charts/graphistry-helm/templates/caddy/caddy-cfg.yml) and update the configuration as needed.
2. Delete the existing Caddy ConfigMap (`kubectl delete configmap caddy-config -n graphistry`).
3. [Update the Graphistry Helm chart](https://github.com/graphistry/graphistry-helm/tree/main/charts/values-overrides/examples/gke#update-graphistry-deployment) to apply the new configuration.
4. Delete the current Caddy pod to trigger a restart with the updated settings (`kubectl delete $(kubectl get pods -n graphistry -o name | grep caddy-graphistry) -n graphistry`).
5. Verify that the new ConfigMap is created and applied to the new Caddy pod (`kubectl get configmap caddy-config -n graphistry -o yaml`).

Additionally, review the general and global [values in the Graphistry chart](https://github.com/graphistry/graphistry-helm/blob/main/charts/graphistry-helm/values.yaml), as some are related to the Caddy configuration.
