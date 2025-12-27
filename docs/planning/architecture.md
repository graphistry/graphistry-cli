# Graphistry Architecture

See also:

* [Hardware and software](hardware-software.md)
* [Deployment planning](deployment-planning.md)
* [Threat modeling](../security/threatmodel.md) and [authentication](../security/authentication.md)

## Deployment Model

Client/server model for direct users, embedding users, and admins - [Live diagram](https://drive.google.com/file/d/1h6hOM2gJYrUNpaxtdRXRO8X8ya8iusFr/view?usp=sharing)

Engines and connectors - [chart](https://drive.google.com/file/d/1SDP9nEWC0KNCqcKagbO54mfspa7tX6Yu/view?usp=sharing)

## Server Software Architecture

[Live diagram](https://drive.google.com/file/d/1KgWwYtA2YsacUPnuryJcJRHBVgvEnH9p/view?usp=sharing)

## Service Overview

Graphistry uses a microservices architecture with GPU-accelerated graph processing. All GPU services communicate using Apache Arrow format for high-performance data exchange.

### Proxy Layer

| Service | Role |
|---------|------|
| **caddy** | External SSL/TLS termination, primary entry point (ports 80, 443) |
| **nginx** | Internal reverse proxy, routes requests to backend services |

### Frontend Services

| Service | Role |
|---------|------|
| **nexus** | Django backend API, user management, dataset metadata, file uploads |
| **streamgl-viz** | WebGL graph visualization frontend, WebSocket/Falcor protocol |
| **pivot** | Investigation interface for graph exploration |

### GPU Services

| Service | Role | GPU Technology |
|---------|------|----------------|
| **streamgl-gpu** | Graph layout computation (ForceAtlas2) | OpenCL |
| **forge-etl-python** | GPU ETL orchestrator, data processing | CUDA/cuDF |
| **dask-cuda-worker** | Distributed GPU data transformation | RAPIDS/cuDF |

### Infrastructure Services

| Service | Role |
|---------|------|
| **postgres** | Metadata storage (users, sessions, dataset metadata) |
| **redis** | Caching, session storage, message queuing |
| **dask-scheduler** | Distributed computing coordinator |

## Data Flow

### Graph Visualization Pipeline

```
1. Upload      User uploads data via API or UI
                    |
                    v
2. Ingest      nexus -> forge-etl-python (file processing)
                    |
                    v
3. Transform   forge-etl-python -> dask-cuda-worker (RAPIDS GPU processing)
                    |
                    v
4. Layout      streamgl-gpu (ForceAtlas2 GPU layout computation)
                    |
                    v
5. Render      streamgl-viz -> Browser (WebGL visualization)
```

### Request Flow

```
Browser -> caddy:443 -> nginx -> backend services
                          |
                          +-- nexus:8000 (API, auth)
                          +-- streamgl-viz:8080 (visualization)
                          +-- forge-etl-python:8080 (data)
                          +-- streamgl-gpu:8080 (layout)
```

## Service Dependencies

### Startup Order

Services start in dependency order:

1. **Infrastructure**: postgres, redis
2. **Distributed Computing**: dask-scheduler, dask-cuda-worker
3. **Core API**: nexus
4. **GPU Services**: forge-etl-python, streamgl-gpu
5. **Applications**: streamgl-viz, pivot, notebook
6. **Proxies**: nginx, caddy

### Runtime Dependencies

| Service | Depends On |
|---------|------------|
| nexus | postgres |
| forge-etl-python | dask-scheduler, dask-cuda-worker, postgres, redis |
| dask-cuda-worker | dask-scheduler, GPU |
| streamgl-gpu | GPU (OpenCL) |
| streamgl-viz | nexus, forge-etl-python |

## GPU Resource Management

### Per-Service GPU Assignment

Each GPU service can be assigned to specific GPUs via environment variables:

```bash
# Global default
CUDA_VISIBLE_DEVICES=0,1,2,3

# Per-service overrides
FORGE_CUDA_VISIBLE_DEVICES=0,1     # forge-etl-python
STREAMGL_CUDA_VISIBLE_DEVICES=2,3  # streamgl-gpu
DCW_CUDA_VISIBLE_DEVICES=0,1       # dask-cuda-worker
```

See [Environment Variables](../app-config/environment-variables.md#per-service-gpu-assignment) for details.

### Multi-Worker Configuration

Workers are distributed across GPUs using round-robin assignment:

```bash
CUDA_VISIBLE_DEVICES=0,1,2,3
FORGE_NUM_WORKERS=16      # 4 workers per GPU
STREAMGL_NUM_WORKERS=16   # 4 workers per GPU
DASK_NUM_WORKERS=4        # 1 worker per GPU
```

See [GPU Configuration Wizard](../tools/gpu-config-wizard.md) for automated configuration.

## Network Architecture

### Internal Network

All services communicate on an internal Docker network (`grph_net`). Only caddy exposes external ports.

### Ports

| Port | Service | Access |
|------|---------|--------|
| 80, 443 | caddy | External (user access) |
| 8000 | nexus | Internal |
| 8080 | streamgl-*, forge-etl-python | Internal |
| 5432 | postgres | Internal |
| 6379 | redis | Internal |

### SSL/TLS

- **External**: Caddy handles SSL termination with automatic certificate management
- **Internal**: Services communicate over HTTP within Docker network

## Scaling

### Horizontal Scaling

- **GPU workers**: Increase `FORGE_NUM_WORKERS`, `STREAMGL_NUM_WORKERS`, `DASK_NUM_WORKERS`
- **Multi-GPU**: Add GPUs via `CUDA_VISIBLE_DEVICES`

### Vertical Scaling

- **GPU memory**: Use GPUs with more VRAM for larger graphs
- **CPU/RAM**: More cores and memory for larger concurrent user counts

See [Deployment Planning](deployment-planning.md) for capacity guidance
