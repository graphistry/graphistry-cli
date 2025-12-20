# Troubleshooting Guide

Common issues, error patterns, and solutions for Graphistry deployments.

## Quick Diagnostics

Before diving into specific issues, run these diagnostic commands:

```bash
# Service status
./graphistry ps

# GPU availability
nvidia-smi

# Check for restart loops
docker ps -a | grep -E "(Restarting|Exited)"

# View recent errors across all services
./graphistry logs --tail=50 | grep -i error
```

## Log Configuration

### Environment Variables

Configure logging in `data/config/custom.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `LOG_LEVEL` | System-wide log level | `INFO` |
| `GRAPHISTRY_LOG_LEVEL` | Graphistry application log level | `INFO` |

**Log levels**: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`

```bash
# Development / Debugging
LOG_LEVEL=DEBUG
GRAPHISTRY_LOG_LEVEL=DEBUG
```

**Notes**:
- `TRACE`: Slow due to heavy CPU-GPU traffic, may expose secrets
- `DEBUG`: Large log volumes, enable log rotation
- `INFO`: Recommended for production
- Always reset to `INFO` after debugging

### Viewing Logs

```bash
# All services with timestamps
./graphistry logs -f -t --tail=100

# Specific services
./graphistry logs -f forge-etl-python streamgl-gpu streamgl-viz

# Filter for errors
./graphistry logs --tail=500 | grep -i "error\|exception\|failed"

# Since specific time
./graphistry logs --since 1h
```

### Log Driver Configuration

For local log access, ensure Docker uses the JSON log driver. Edit `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

Then restart Docker: `sudo service docker restart`

## Telemetry for Troubleshooting

OpenTelemetry provides distributed tracing and metrics for diagnosing complex issues across services.

### Enabling Telemetry

Configure in `data/config/telemetry.env`:

```bash
ENABLE_OPEN_TELEMETRY=true
OTEL_COMPOSE_FILE=telemetry.yml
```

Restart services: `./graphistry stop && ./graphistry up -d`

### Using Traces for Debugging

When telemetry is enabled, access Jaeger for distributed tracing:
- Default: `http://$GRAPHISTRY_HOST:16686/jaeger/`
- Behind Caddy: `https://$GRAPHISTRY_HOST/jaeger/`

**Key trace points**:
- Root span: `streamgl-viz: handleFalcorSocketConnections`
- GPU worker actions: play, read, stop spans
- Data fetching: ETL dataset fetch spans from `forge-etl-python`

**Use cases**:
- Identify which service caused an error
- Find latency bottlenecks in the rendering pipeline
- Track request flow from browser to GPU workers

### Using Metrics for Debugging

Access Prometheus for metrics:
- Default: `http://$GRAPHISTRY_HOST:9091/prometheus/`
- Behind Caddy: `https://$GRAPHISTRY_HOST/prometheus/`

**Critical metrics to monitor**:
- `worker_read_crashes_total`: GPU worker crashes
- `forge_etl_python_upload_*`: Upload and dataset creation metrics

### GPU Monitoring

Grafana with NVIDIA DCGM provides GPU health dashboards:
- Default: `http://$GRAPHISTRY_HOST:3000`
- Behind Caddy: `https://$GRAPHISTRY_HOST/grafana/`

See [Telemetry Documentation](../telemetry/docker-compose.md) for full configuration.

## NVIDIA Driver Troubleshooting

### Verify Driver Installation

```bash
# Check driver version
nvidia-smi

# Expected output shows driver version, CUDA version, GPU info
# If command not found or fails, driver is not installed/loaded
```

### Driver Not Loaded

**Symptoms**: `nvidia-smi` returns "command not found" or "driver not loaded"

```bash
# Check if driver module is loaded
lsmod | grep nvidia

# Check for driver installation
dpkg -l | grep nvidia-driver    # Debian/Ubuntu
rpm -qa | grep nvidia-driver    # RHEL/CentOS

# Check kernel messages for GPU errors
dmesg | grep -i nvidia
```

**Solutions**:

```bash
# Reinstall driver (Ubuntu example)
sudo apt update
sudo apt install --reinstall nvidia-driver-535

# Or use NVIDIA's official installer
# Download from https://www.nvidia.com/drivers

# After install, reboot
sudo reboot
```

### Driver/CUDA Version Mismatch

**Symptoms**: CUDA errors, library version conflicts

Check compatibility:
```bash
# Driver's maximum supported CUDA version
nvidia-smi | grep "CUDA Version"

# Installed CUDA toolkit version
nvcc --version
```

The driver's CUDA version must be >= the toolkit version. See [NVIDIA CUDA Compatibility](https://docs.nvidia.com/deploy/cuda-compatibility/).

### GPU Not Visible

```bash
# List all NVIDIA devices
lspci | grep -i nvidia

# Check if GPU is recognized by driver
nvidia-smi -L

# For multi-GPU, verify all GPUs listed
nvidia-smi --query-gpu=index,name,uuid --format=csv
```

**Solutions**:
- Check PCIe seating and power connections
- Update system BIOS
- Check for GPU in BIOS settings (may be disabled)

### Persistence Mode

For production, enable persistence mode to reduce GPU initialization latency:

```bash
# Enable persistence mode
sudo nvidia-smi -pm 1

# Make persistent across reboots
sudo systemctl enable nvidia-persistenced
sudo systemctl start nvidia-persistenced
```

## Docker NVIDIA Runtime

### Verify Runtime Installation

```bash
# Check if nvidia runtime is available
docker info | grep -i runtime

# Should show: Runtimes: io.containerd.runc.v2 nvidia runc

# Test GPU access in container
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

### Runtime Not Found

**Symptoms**: `docker: Error response from daemon: could not select device driver`

```bash
# Install NVIDIA Container Toolkit
# Ubuntu/Debian
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
sudo apt install -y nvidia-container-toolkit

# RHEL/CentOS
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo yum install -y nvidia-container-toolkit
```

### Configure Docker Runtime

```bash
# Configure Docker to use nvidia runtime
sudo nvidia-ctk runtime configure --runtime=docker

# Restart Docker
sudo systemctl restart docker

# Verify configuration
cat /etc/docker/daemon.json
```

Expected `/etc/docker/daemon.json`:
```json
{
  "runtimes": {
    "nvidia": {
      "args": [],
      "path": "nvidia-container-runtime"
    }
  }
}
```

### Set NVIDIA as Default Runtime

For Graphistry, set nvidia as the default runtime:

```json
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "args": [],
      "path": "nvidia-container-runtime"
    }
  }
}
```

Then restart Docker: `sudo systemctl restart docker`

### GPU Access Denied in Container

**Symptoms**: Container starts but GPU not accessible

```bash
# Check container GPU access
docker exec -it <container> nvidia-smi

# Verify CUDA_VISIBLE_DEVICES
docker exec -it <container> env | grep CUDA
```

**Solutions**:
- Ensure `--gpus all` or specific GPU assignment in compose
- Check cgroup permissions
- Verify nvidia-container-toolkit version matches driver

## Kubernetes NVIDIA GPU Operator

### Verify Operator Installation

```bash
# Check GPU Operator pods
kubectl get pods -n gpu-operator

# All pods should be Running/Completed
# Key pods: nvidia-driver-daemonset, nvidia-device-plugin, gpu-feature-discovery

# Check GPU resources on nodes
kubectl describe nodes | grep -A5 nvidia.com/gpu
```

### Operator Not Deploying

**Symptoms**: GPU Operator pods stuck in Pending/CrashLoopBackOff

```bash
# Check operator logs
kubectl logs -n gpu-operator -l app=gpu-operator

# Check driver daemonset
kubectl logs -n gpu-operator -l app=nvidia-driver-daemonset

# Check events
kubectl get events -n gpu-operator --sort-by='.lastTimestamp'
```

**Common causes**:
- Pre-installed drivers conflict: Use `--set driver.enabled=false` if host has drivers
- Kernel headers missing: Install `linux-headers-$(uname -r)`
- Unsupported OS/kernel version

### Device Plugin Issues

**Symptoms**: Nodes show 0 GPU capacity

```bash
# Check device plugin
kubectl logs -n gpu-operator -l app=nvidia-device-plugin-daemonset

# Verify node labels
kubectl get nodes --show-labels | grep nvidia

# Check allocatable resources
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

**Solutions**:
```bash
# Restart device plugin
kubectl rollout restart daemonset nvidia-device-plugin-daemonset -n gpu-operator

# If using MIG, ensure MIG mode configured correctly
nvidia-smi mig -lgi
```

### Pod Can't Access GPU

**Symptoms**: Pod pending with "Insufficient nvidia.com/gpu"

```bash
# Check GPU allocation
kubectl describe node <node-name> | grep -A10 "Allocated resources"

# Check pod resource requests
kubectl describe pod <pod-name> | grep -A5 "Limits"
```

**Pod GPU resource spec**:
```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

### Time-Slicing Configuration

For sharing GPUs across pods:

```yaml
# gpu-operator values
devicePlugin:
  config:
    name: time-slicing-config
    default: any
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  namespace: gpu-operator
data:
  any: |-
    version: v1
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 4
```

### MIG (Multi-Instance GPU) Issues

```bash
# Check MIG status
nvidia-smi mig -lgi

# Enable MIG mode (requires reboot)
sudo nvidia-smi -mig 1

# Create MIG instances
sudo nvidia-smi mig -cgi 9,9,9 -C
```

For Kubernetes MIG support, configure GPU Operator with MIG strategy:
```bash
helm upgrade gpu-operator nvidia/gpu-operator \
  --set mig.strategy=single
```

## Common Issues

### Service Won't Start

**Symptoms**: Container in restart loop, exits immediately

```bash
# Check container logs
./graphistry logs <service_name>

# Check service status
./graphistry ps

# Check for port conflicts
docker ps -a
netstat -tulpn | grep <port>
```

**Solutions**:
- Port conflict: `./graphistry down` and check for conflicting containers
- Missing dependencies: Check service startup order
- Configuration error: Review `custom.env` for syntax errors

### Database Connection Issues

**Symptoms**: Nexus won't start, authentication failures, data not persisting

```bash
# Check postgres health
./graphistry logs postgres

# Test database connectivity
docker exec -it compose_postgres_1 pg_isready

# Check connection from nexus
docker exec -it compose_nexus_1 /bin/bash
```

**Solutions**:
- Wait for postgres to be ready before nexus starts
- Reset database: `./graphistry down -v && ./graphistry up -d` (WARNING: deletes all data)
- Check disk space: `docker system df`

### Memory Issues

**Symptoms**: OOM errors, slow performance, container crashes

```bash
# Monitor resource usage
docker stats

# Check system memory
free -h

# Check GPU memory
nvidia-smi
```

**Solutions**:
- Clean Docker resources: `docker system prune -f`
- Reduce worker counts in `custom.env`
- Enable GPU memory watcher (see [Performance Tuning](performance-tuning.md#gpu-memory-watcher))

### Network/Connectivity Issues

**Symptoms**: Services can't communicate, API timeouts, WebSocket failures

```bash
# Check all services running
./graphistry ps

# Test inter-service connectivity
docker exec -it compose_nexus_1 ping compose_postgres_1
```

**Solutions**:
- Restart affected services
- Check firewall rules for required ports
- Verify Caddy configuration

### Upload Failures

Check upload size limits in `custom.env`:
```bash
UPLOAD_MAX_SIZE=1G
GRAPHISTRY_HTTP_AGENT_TIMEOUT_MS=120000
```

## Service-Specific Issues

### forge-etl-python

```bash
# Check worker health
./graphistry logs forge-etl-python --tail=100

# Verify GPU assignment
./graphistry logs forge-etl-python | grep "GPU initialized"
```

Common issues:
- cuDF memory errors: Reduce cache sizes or enable GPU watcher
- Worker crashes: Check `FORGE_NUM_WORKERS` matches available GPU memory

### streamgl-gpu

```bash
# Check GPU worker status
./graphistry logs streamgl-gpu --tail=100

# Verify OpenCL
./graphistry logs streamgl-gpu | grep -i "opencl\|gpu"
```

Common issues:
- OpenCL UUID format: Use integer format (`0,1,2`) not UUID format for `STREAMGL_GPU_CUDA_VISIBLE_DEVICES`
- PM2 process manager issues: Check for worker spawn errors

### streamgl-viz

```bash
./graphistry logs streamgl-viz --tail=100
```

Common issues:
- WebSocket connection failures: Check proxy configuration
- Session timeout: Adjust `GRAPHISTRY_VIZ_TO_GPU_TIMEOUT_MS`

## Recovery Procedures

### Soft Restart

```bash
./graphistry restart <service_name>
```

### Hard Restart

```bash
./graphistry up -d --force-recreate --no-deps <service_name>
```

### Full Environment Reset

```bash
./graphistry down -v   # WARNING: deletes user database
docker system prune -f
./graphistry up -d
```

## Getting Help

Collect diagnostic information:
```bash
./graphistry ps > diagnostics.txt
./graphistry logs --tail=500 >> diagnostics.txt
nvidia-smi >> diagnostics.txt
docker info >> diagnostics.txt
cat VERSION >> diagnostics.txt
```

See also:
- [Debug Logs](debug-logs.md)
- [Performance Tuning](performance-tuning.md)
- [FAQ](debug-faq.md)
- [Telemetry](../telemetry/docker-compose.md)
