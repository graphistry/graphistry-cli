# Telemetry

Graphistry services can be configured to export telemetry information using the [OpenTelemetry](https://opentelemetry.io/) standard. This includes logs, metrics, and traces.

When enabled, telemetry sent to the local Graphistry [OTEL Collector](https://opentelemetry.io/docs/collector/) service, and from there, dispatches to any observability tool that is compatible with the OpenTelemetry standard (e.g. Prometheus, Jaeger, Grafana Cloud, etc.).

To use telemetry with Graphistry, you need to:

* Enable telemetry collection recording in one or more Graphistry services
* Configure which users each service will monitor (see section on feature flags)
* Enable the telemetry collector service
* Configure the forwarding from the telemetry collector to an observability database/UI
* Optionally, setup a local observability database/UI

## Configuration

By default, Graphistry does not collect and export OpenTelemetry data.

To configure collection (but not yet turn on), enable the custom environment variable ENABLE_OPEN_TELEMETRY in your configuration file: `$GRAPHISTRY_HOME/data/config/telemetry.env`

### Example: Graphana Cloud
For example, this is the configuration template for [Grafana Cloud](https://grafana.com/), which includes a free tier:

```bash
ENABLE_OPEN_TELEMETRY=true

OTEL_COLLECTOR_OTLP_USERNAME="XYZ"   # e.g. Grafana Cloud Instance ID for OTLP
OTEL_COLLECTOR_OTLP_PASSWORD="PQR"   # e.g. Grafana Cloud API Token for OTLP
OTEL_COLLECTOR_OTLP_HTTP_ENDPOINT="https://hostname.grafana.net/otlp"   # e.g. Grafana OTLP HTTP endpoint 
OTEL_COLLECTOR_COMPOSE_FILE=otel-collector.yml
OTEL_COLLECTOR_CONF_FILE=./etc/otel-collector/otel-collector-config.yml
```

### Example: Local Jaeger and Prometheus

For example, this is the configuration template for a local development env that launches local instances of Jaeger and Prometheus alongside the OpenTelemetry Collector:

```bash
ENABLE_OPEN_TELEMETRY=true

OTEL_COLLECTOR_OTLP_HTTP_ENDPOINT="https://hostname.grafana.net/otlp"   # e.g. Grafana OTLP HTTP endpoint 
OTEL_COLLECTOR_COMPOSE_FILE=compose/otel-collector.dev.yml
OTEL_COLLECTOR_CONF_FILE=./etc/otel-collector/otel-collector-config.dev.yml
OTEL_COLLECTOR_PUB_COMPOSE_FILE=compose/otel-collector-pub.yml

PROMETHEUS_COMPOSE_FILE=compose/prometheus.yml
PROMETHEUS_PUB_COMPOSE_FILE=compose/prometheus-pub.yml

JAEGER_COMPOSE_FILE=compose/jaeger.yml
JAEGER_PUB_COMPOSE_FILE=compose/jaeger-pub.yml
```

## Usage

By default, the telemetry services are disabled, so using `./release` commands ((alias for `docker compose ...` with  settings like logging) will not trigger telemetry collection, forwarding, nor telemetry UIs

### Turning on

The command `./release` will automatically start those services when `ENABLE_OPEN_TELEMETRY=true`.  Once the services are online, we can access these useful links for development and operations:

* OTEL Collector metrics for Prometheus: http://localhost:8889/metrics
* Prometheus dashboard: http://$GRAPHISTRY_HOST:9091
* Jaeger dashboard: http://$GRAPHISTRY_HOST:16686

### Audience selection via feature flags

The feature flag in the web admin panel (waffle) for OpenTelemetry is `flag_ot_traces`, and it is off by default

You need to be admin in order to change its value, this flag controls at runtime which users can export telemetry data

You can set monitoring to no/all/select users
