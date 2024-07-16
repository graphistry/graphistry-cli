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
OTEL_COLLECTOR_COMPOSE_FILE=otel-collector.dev.yml
OTEL_COLLECTOR_CONF_FILE=./etc/otel-collector/otel-collector-config.dev.yml
OTEL_COLLECTOR_PUB_COMPOSE_FILE=otel-collector-pub.yml

PROMETHEUS_COMPOSE_FILE=prometheus.yml
PROMETHEUS_PUB_COMPOSE_FILE=prometheus-pub.yml

JAEGER_COMPOSE_FILE=jaeger.yml
JAEGER_PUB_COMPOSE_FILE=jaeger-pub.yml
```
### Caddyfile - reverse proxy set up 

To acces the otel services, you need to set up routes to the various services in the Caddyfile. An example Caddyfile with the required routes is provided, but may require merging into your existing Caddyfile. 

1. Create a backup copy of you current Caddyfile: `$GRAPHISTRY_HOME/data/config/Caddyfile`.
2. If you use the default Caddyfile with no changes, then you can simply copy in `$GRAPHISTRY_HOME/data/config/Caddyfile.otel-setup to in `$GRAPHISTRY_HOME/data/config/Caddyfile`. Otherwise, copy the handle directives for the various services into your existing Caddyfile. Copy the following sections into the existing Caddyfile: 

```
    # Routes for jaeger
      ...
    # Route to prometheus
      ...
    # Routes for Grafana
      ...
```
3. restart caddy with:

```
cd $GRAPHISTRY_HOME
docker compose up -d --force-recreate caddy
```

### Usage

By default, the telemetry services are disabled. To enable, set `ENABLE_OPEN_TELEMETRY=true` in `$GRAPHISTRY_HOME/data/config/telemetry.env`.

The `./release` script in $GRAPHISTRY_HOME will automatically start those services when `ENABLE_OPEN_TELEMETRY=true`.  The `./release` script is anologous to `docker compose ...`, but will not trigger telemetry collection, forwarding, nor telemetry UIs unless ENABLE_OPEN_TELEMETRY is set to true and the services are properly configured. 

To start the otel services, run: 
```
cd $GRAPHISTRY_HOME
./release up -d
```

Once the services are online, we can access these links for development and operations:

* OTEL Collector metrics for Prometheus: https://$GRAPHISTRY_HOST:8889/metrics
* Prometheus dashboard: https://$GRAPHISTRY_HOST/prometheus/
* Jaeger dashboard: https://$GRAPHISTRY_HOST/jaeger/ 
* Grafana dashboard: https://$GRAPHISTRY_HOST/grafana/
   
### Audience selection via feature flags

The feature flag in the web admin panel (waffle) for OpenTelemetry is `flag_ot_traces`, and it is off by default

You need to be admin in order to change its value, this flag controls at runtime which users can export telemetry data

You can set monitoring to no/all/select users
