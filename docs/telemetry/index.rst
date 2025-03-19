Telemetry
========================

.. toctree::
  :maxdepth: 1

  docker-compose
  kubernetes


Deploying Telemetry Services for Graphistry
------------------------

Graphistry leverages **OpenTelemetry** to collect and export telemetry data, such as **metrics** and **traces**, from its services. Regardless of whether you are using the **Docker Compose** platform or the **Kubernetes** platform, the telemetry stack can be deployed in **three key modes**, offering flexibility in how data is collected and routed to observability tools. **Graphistry's telemetry stack** provides flexible deployment options for collecting and visualizing metrics and traces.

Both **Docker Compose and Kubernetes platforms** share **common specifications** for deploying OpenTelemetry, ensuring seamless integration and consistent behavior across environments. Whether you choose to forward telemetry data to external services, use packaged observability tools, or combine both methods in hybrid mode, the platforms offer a unified and scalable approach to telemetry data collection and export.

Common Deployment Modes
^^^^^^^^^^^^^^^^^^^^^^^^

1. **Forwarding to External Services**

   * Telemetry data is forwarded to external observability services (e.g., **Grafana Cloud**, **Datadog**, etc.).
   * Both platforms support configuration for sending telemetry data to **OTLP-compatible** endpoints.

2. **Using Packaged Observability Tools**

   * A local stack of observability tools (e.g., **Prometheus**, **Grafana**, **Jaeger**, **NVIDIA/dcgm-exporter**, etc.) is deployed to collect and visualize telemetry data, including GPU metrics.
   * Both platforms offer the option to deploy this self-contained stack for on-premises monitoring.

3. **Hybrid Mode**

   * Can combine both local observability tools and external services for telemetry data routing.
   * Data can be sent both to internal tools (e.g., **Prometheus**) and external observability platforms for comprehensive monitoring.
   * Provides more flexibility for custom deployments, such as **skipping forwarding to the OpenTelemetry Collector** and **forwarding to a custom vendor-based OTLP-compatible collector**, or adding more rules to the telemetry processing pipeline.

Common Technical Specifications
^^^^^^^^^^^^^^^^^^^^^^^^

- **Telemetry Collection**: Both platforms use the OpenTelemetry Collector or compatible OTLP collectors to gather telemetry data (metrics, traces).
- **Endpoint Configuration**: Both platforms allow specifying endpoints for sending data, including local tools and external services like Grafana Cloud.
- **Authentication**: External services require credentials (e.g., API tokens, access keys) for secure data transmission.
- **Secure Communication**: Both platforms support encrypted communication channels for telemetry data transfer.
- **Credential Management**: Platforms enable secure management of credentials for safe data forwarding to external services.
- **Scalability**: Both platforms support scaling the telemetry stack, including the OpenTelemetry Collector and other observability components.
- **Telemetry Configuration**: Both platforms allow fine-tuning settings for data collection, export formats, and the types of telemetry data.
- **Flexible Deployment Options**: Both platforms support various configurations, from self-contained observability stacks to combining internal and external tools.
