# Environment Variables Reference

This page provides a centralized reference for all environment variables that can be configured in `data/config/custom.env`.

For changes to take effect, restart the affected services:
```bash
./graphistry stop && ./graphistry up -d
# Or for specific services:
./graphistry stop forge-etl-python && ./graphistry up -d
```

## Logging Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `LOG_LEVEL` | System-wide log level | `INFO` |
| `GRAPHISTRY_LOG_LEVEL` | Graphistry application log level | `INFO` |

**Log levels**: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`

**Notes**:
- `TRACE`: Slow due to heavy CPU-GPU traffic
- `DEBUG`: Large log volumes requiring rotation
- `INFO`: May cause large log volumes over time

## Service Restart Schedules

| Variable | Description | Default |
|----------|-------------|---------|
| `CRON_RESTART` | Cron schedule for all service restarts | disabled |
| `STREAMGL_GPU_WORKER_CRON_RESTART` | Cron schedule for streamgl-gpu worker restarts | disabled |

**Examples**:
```bash
CRON_RESTART="5 */12 * * *"                    # 5min past every 12th hour
STREAMGL_GPU_WORKER_CRON_RESTART="5 */8 * * *"  # 5min past every 8th hour
```

## Timeout and Retry Settings

### HTTP Agent Settings (Transport Layer)

| Variable | Description | Default |
|----------|-------------|---------|
| `GRAPHISTRY_HTTP_AGENT_TIMEOUT_MS` | HTTP request timeout | 60000 |
| `GRAPHISTRY_HTTP_AGENT_KEEPALIVE_MS` | HTTP keep-alive duration | 60000 |

### Service Communication (Application Layer)

| Variable | Description | Default |
|----------|-------------|---------|
| `GRAPHISTRY_VIZ_TO_GPU_TIMEOUT_MS` | streamgl-viz to streamgl-gpu timeout | 30000 |
| `GRAPHISTRY_VIZ_TO_GPU_RETRY_COUNT` | Number of retries for viz-to-gpu requests | 10 |

## GPU Memory Watcher

Optional safety feature for `forge-etl-python` that monitors GPU memory and can automatically terminate runaway processes before OOM errors.

| Variable | Description | Default |
|----------|-------------|---------|
| `FEP_GPU_WATCHER_ENABLED` | Enable GPU memory monitoring (`1` to enable) | disabled |
| `FEP_GPU_WATCHER_POLL_SECONDS` | How often to check GPU memory | 15 |
| `FEP_GPU_WATCHER_HEARTBEAT_SECONDS` | Log heartbeat interval (0 = disabled) | disabled |
| `FEP_GPU_WATCHER_WARN_THRESHOLD` | Log warning when memory exceeds this | disabled |
| `FEP_GPU_WATCHER_KILL_THRESHOLD` | Start deferred kill process | disabled |
| `FEP_GPU_WATCHER_IDLE_THRESHOLD` | Kill if still above this after defer period | disabled |
| `FEP_GPU_WATCHER_KILL_DEFER_SECONDS` | Wait time before killing | 300 |
| `FEP_GPU_WATCHER_EMERGENCY_THRESHOLD` | Immediate kill (no defer) | disabled |

**Threshold formats**: Percentage (`70%`, `90%`) or absolute MB (`8192MB`, `16384MB`)

**Example production configuration**:
```bash
FEP_GPU_WATCHER_ENABLED=1
FEP_GPU_WATCHER_POLL_SECONDS=30
FEP_GPU_WATCHER_WARN_THRESHOLD=70%
FEP_GPU_WATCHER_KILL_THRESHOLD=90%
FEP_GPU_WATCHER_IDLE_THRESHOLD=60%
FEP_GPU_WATCHER_EMERGENCY_THRESHOLD=95%
```

See [Performance Tuning - GPU Memory Watcher](../debugging/performance-tuning.md#gpu-memory-watcher) for details.

## Per-Service GPU Assignment

By default, `CUDA_VISIBLE_DEVICES` applies to all GPU services. For advanced multi-GPU configurations, override per service.

**Fallback chain**:
1. Service-specific variable (e.g., `FORGE_CUDA_VISIBLE_DEVICES`)
2. Global `CUDA_VISIBLE_DEVICES`
3. Default: GPU 0

| Variable | Service |
|----------|---------|
| `CUDA_VISIBLE_DEVICES` | Global default for all services |
| `FORGE_CUDA_VISIBLE_DEVICES` | forge-etl-python |
| `STREAMGL_CUDA_VISIBLE_DEVICES` | streamgl-gpu |
| `DCW_CUDA_VISIBLE_DEVICES` | dask-cuda-worker |
| `DASK_SCHEDULER_CUDA_VISIBLE_DEVICES` | dask-scheduler |
| `GAK_PUBLIC_CUDA_VISIBLE_DEVICES` | graph-app-kit-public |
| `GAK_PRIVATE_CUDA_VISIBLE_DEVICES` | graph-app-kit-private |
| `NOTEBOOK_CUDA_VISIBLE_DEVICES` | notebook |

**Format support**:
- Integer format: `0,1,2,3` (standard CUDA format)
- UUID format: `GPU-xxx,GPU-yyy` (VMware/Nutanix/MIG environments)
- Mixed format NOT supported for streamgl-gpu

**Examples**:
```bash
# Single GPU (default)
# Leave all commented out, defaults to GPU 0

# Multi-GPU isolation
FORGE_CUDA_VISIBLE_DEVICES=0
STREAMGL_CUDA_VISIBLE_DEVICES=1

# Multi-GPU shared (round-robin assignment)
CUDA_VISIBLE_DEVICES=0,1,2,3

# VMware/Nutanix/MIG
CUDA_VISIBLE_DEVICES=GPU-xxx,GPU-yyy
```

See [Performance Tuning - Per-Service GPU Assignment](../debugging/performance-tuning.md#per-service-gpu-assignment) for details.

## Multi-Worker GPU Configuration

Configure worker counts for multi-GPU utilization. Workers are assigned to GPUs using round-robin distribution.

| Variable | Description | Default |
|----------|-------------|---------|
| `FORGE_NUM_WORKERS` | forge-etl-python Hypercorn workers | 4 |
| `STREAMGL_NUM_WORKERS` | streamgl-gpu workers | 4 |
| `DASK_NUM_WORKERS` | dask-cuda-worker instances | 1 |

**GPU underutilization policy** (matches PyTorch/dask-cuda behavior):
- Workers < GPUs: Service logs WARNING, unused GPUs remain idle
- Workers > GPUs: Round-robin assignment distributes workers evenly
- Workers = GPUs: One-to-one assignment (optimal)

**Examples**:
```bash
# Dual GPU
CUDA_VISIBLE_DEVICES=0,1
FORGE_NUM_WORKERS=8
STREAMGL_NUM_WORKERS=8
DASK_NUM_WORKERS=2

# Quad GPU
CUDA_VISIBLE_DEVICES=0,1,2,3
FORGE_NUM_WORKERS=16
STREAMGL_NUM_WORKERS=16
DASK_NUM_WORKERS=4
```

**Tip**: Use the [GPU Configuration Wizard](../tools/gpu-config-wizard.md) to auto-generate optimal settings:
```bash
./etc/scripts/gpu-config-wizard.sh -E ./data/config/custom.env
```

See [Performance Tuning - Multi-Worker Configuration](../debugging/performance-tuning.md#multi-worker-configuration) for details.

## RMM GPU Settings

RAPIDS Memory Manager settings for GPU memory allocation.

| Variable | Description | Default |
|----------|-------------|---------|
| `RMM_ALLOCATOR` | Allocator type: `default` or `managed` | `managed` |
| `RMM_POOL` | Enable memory pooling | `TRUE` |
| `RMM_INITIAL_POOL_SIZE` | Initial pool size in bytes | `33554432` (32MB) |
| `RMM_MAXIMUM_POOL_SIZE` | Maximum pool size in bytes | None (full GPU) |
| `RMM_ENABLE_LOGGING` | Enable RMM logging | `FALSE` |

**Note**: For vGPU environments (VMware, Nutanix), set `RMM_ALLOCATOR=default` as vGPUs don't support CUDA Unified Memory.

See [Performance Tuning - RMM GPU Settings](../debugging/performance-tuning.md#rmm-gpu-settings) for details.

## Cache Configuration

Control CPU and GPU cache sizes for `forge-etl-python`. Sizes are per-worker.

| Variable | Description | Default |
|----------|-------------|---------|
| `N_CACHE_CPU_OVERRIDE` | Override all CPU cache counts | varies |
| `N_CACHE_CPU_FULL_OVERRIDE` | Override large CPU cache counts | varies |
| `N_CACHE_CPU_SMALL_OVERRIDE` | Override small CPU cache counts | varies |
| `N_CACHE_GPU_OVERRIDE` | Override all GPU cache counts | varies |
| `N_CACHE_GPU_FULL_OVERRIDE` | Override large GPU cache counts | ~30 |
| `N_CACHE_GPU_SMALL_OVERRIDE` | Override small GPU cache counts | varies |

**Important GPU caches**:
- `N_CACHE_ROUTES_SHAPER_TIMEBAR`
- `N_CACHE_ROUTES_SHAPER_HISTOGRAM`
- `N_CACHE_ROUTES_SHAPER_SELECT_IDS_IN_GROUP`
- `N_CACHE_ARROW_LOADER_FETCH_WARM`

**Important CPU caches**:
- `N_CACHE_ARROW_LOADER_FETCH_VGRAPH`
- `N_CACHE_ARROW_LOADER_FETCH_ENCODINGS`
- `N_CACHE_ARROW_LOADER_FETCH_HELPER`
- `N_CACHE_ARROW_DOWNLOADER_FETCH_UNSHAPED`
- `N_CACHE_ARROW_DOWNLOADER_FETCH_SHAPE`

See [Performance Tuning - Cache Size](../debugging/performance-tuning.md#cache-size) for details.

## Upload Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `UPLOAD_MAX_SIZE` | Maximum upload size | `1G` (private), `200M` (Hub) |

**Examples**: `1M`, `100M`, `1G`, `10G`

## Cookie Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `COOKIE_SECURE` | Use secure cookies (requires HTTPS) | `false` |
| `COOKIE_SAMESITE` | SameSite cookie policy | `Lax` |

**For authenticated cross-site iframe embedding over HTTPS**:
```bash
COOKIE_SECURE=true
COOKIE_SAMESITE=None
```

## Cross-Origin Embedding (CORS)

| Variable | Description | Default |
|----------|-------------|---------|
| `CORS_ALLOWED_ORIGINS` | Comma-separated list of additional browser origins allowed for cross-origin API requests and visualization socket handshakes; does not control iframe embedding | empty (no additional origins) |

`CORS_ALLOWED_ORIGINS` is the single source of truth for cross-origin access across the stack — read by
nginx, nexus, pivot, and the visualization realtime socket. **Empty (the default) allows no additional
browser origins for those requests.** This is intentional (earlier releases allowed all origins; that default
was removed for security). It does not prevent an HTTPS site from loading a Graphistry HTTPS page in an
iframe. **Most deployments need no change** — see the authoritative reference in
`data/config/custom.env`. Two distinct cases are easy to conflate:

- **Embedding `https://graphistry.example.com/graph.html` in an iframe on
  `https://dashboard.example.com`**: JavaScript inside the iframe opens the visualization socket from
  the **Graphistry origin**, which passes the socket's own-host check. Do not add the parent page's origin
  to `CORS_ALLOWED_ORIGINS` for this embed. For authenticated cross-site embeds, session cookies need
  `SameSite=None; Secure` (settings above), and the browser must allow third-party cookies. The parent
  page must permit the iframe, and Graphistry's response must permit that parent to frame it. An iframe
  sandboxed without `allow-same-origin` has an opaque origin (`Origin: null` on its socket handshake)
  and is rejected.
- **JavaScript running on `https://dashboard.example.com` directly calling Graphistry's API or socket**:
  list `https://dashboard.example.com` in `CORS_ALLOWED_ORIGINS`. This admits the origin but does not
  authenticate the request or enable credentialed cross-origin REST or socket polling by itself.

```bash
# only when JavaScript on this different host calls Graphistry directly:
CORS_ALLOWED_ORIGINS=https://dashboard.example.com
```

> **Credentialed cross-origin REST requests are not supported.** REST responses do not emit
> `Access-Control-Allow-Credentials`; a separate frontend making browser `fetch` requests must use
> bearer-token / API-key authentication instead of `credentials: 'include'`. Same-origin pages and
> iframe embeds continue to use Graphistry's session cookies.

**Realtime socket (upgrade note):** the visualization's realtime (socket.io) connection now also honors
`CORS_ALLOWED_ORIGINS` on its handshake, for both HTTP polling and WebSocket upgrade. The allowlist
admits an origin; it does **not** authenticate a socket. The visualization socket uses cookie-backed
authentication, and credentialed cross-origin polling is not enabled by this setting. The supported
iframe embed loads Graphistry's own page and makes same-origin socket requests, so its parent origin
needs no socket allowlist entry. A sandboxed iframe without `allow-same-origin` instead sends
`Origin: null` on its socket handshake and is refused.

The first `GET /graph/graph.html?dataset=...` can arrive without `session`; the graph page normally
redirects to a URL containing `session=<Graphistry session ID>`. Its built-in socket client carries
that value on every transport request. Caddy hashes the value to the same engine pod in multi-engine
Kubernetes, then viz keeps each Engine.IO connection on one CPU worker. This is routing, not
authorization or a guarantee of cross-user collaboration: same-account tabs may retain one session,
but a different authenticated user opening its URL is redirected to a fresh session. Anonymous reuse
of an anonymous session is limited to 10 seconds. The app-level two-tab smoke test checks that closing
one tab leaves the other operational; the proxy fixture checks transport routing only.

A **direct Socket.IO handshake** without `session` differs from that expected first page GET. In
multi-engine Kubernetes, it can open a socket but lose its next polling request across engine pods.
Include the Graphistry `session` query on every direct-client connection and reconnect. Compose's
single-engine path has no inter-pod risk. No server-side 422 rejection has been introduced while
direct-client compatibility remains under review. A VPN or changing browser IP does not affect a
session-based route.

> **Marketplace / turnkey deployments** ship with `CORS_ALLOWED_ORIGINS` empty (same-origin only,
> fail-closed) — the same secure default as every other distribution. Set it only if a separate
> different-origin frontend needs browser-side API/socket access.

## Maps / Geospatial

Enable Kepler.gl-based geospatial map visualizations.

| Variable | Description | Default |
|----------|-------------|---------|
| `GRAPHISTRY_ENABLE_KEPLER` | Enable geospatial map support | `false` |

**Example**:
```bash
GRAPHISTRY_ENABLE_KEPLER=true
```

See the [PyGraphistry Maps documentation](https://pygraphistry.readthedocs.io/en/latest/visualization/maps.html) for usage details.

## Quick Reference by Use Case

### Production Hardening
```bash
LOG_LEVEL=INFO
GRAPHISTRY_LOG_LEVEL=INFO
FEP_GPU_WATCHER_ENABLED=1
FEP_GPU_WATCHER_WARN_THRESHOLD=70%
FEP_GPU_WATCHER_KILL_THRESHOLD=90%
FEP_GPU_WATCHER_EMERGENCY_THRESHOLD=95%
COOKIE_SECURE=true
```

### Multi-GPU Setup (4 GPUs)
```bash
CUDA_VISIBLE_DEVICES=0,1,2,3
FORGE_NUM_WORKERS=16
STREAMGL_NUM_WORKERS=16
DASK_NUM_WORKERS=4
```

### Development / Debugging
```bash
LOG_LEVEL=DEBUG
GRAPHISTRY_LOG_LEVEL=DEBUG
```

### VMware / Nutanix vGPU
```bash
RMM_ALLOCATOR=default
CUDA_VISIBLE_DEVICES=GPU-xxx,GPU-yyy
```

### Maps / Geospatial
```bash
GRAPHISTRY_ENABLE_KEPLER=true
```
