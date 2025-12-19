# GPU Configuration Wizard

Auto-configure optimal GPU settings for your Graphistry deployment based on your hardware.

## Overview

The GPU Configuration Wizard simplifies multi-GPU configuration by:
- Auto-detecting available GPUs via `nvidia-smi`
- Supporting 140+ hardware presets for cloud and on-prem environments
- Generating optimal worker counts using a simple replication model
- Exporting settings directly to `custom.env`

## Usage

```bash
# Interactive mode - displays recommended settings
./etc/scripts/gpu-config-wizard.sh

# Export mode - print to stdout (for copying to custom.env)
./etc/scripts/gpu-config-wizard.sh -E

# Export mode - append directly to custom.env file
./etc/scripts/gpu-config-wizard.sh -E ./data/config/custom.env

# Use hardware preset
./etc/scripts/gpu-config-wizard.sh -p aws-p3-8xlarge

# Custom GPU count
./etc/scripts/gpu-config-wizard.sh -n 4

# Specific GPU indices
./etc/scripts/gpu-config-wizard.sh -g 0,2,5-7

# Custom worker multipliers
./etc/scripts/gpu-config-wizard.sh -w 8,8,2

# List all available presets
./etc/scripts/gpu-config-wizard.sh -l
```

## Options

| Option | Description |
|--------|-------------|
| `-n, --gpu-count N` | Use N GPUs (indices 0 to N-1) |
| `-g, --gpu-indices LIST` | Use specific GPUs (e.g., `0,2,5-7` or `GPU-xxx`) |
| `-w, --workers F,S,D` | Worker multipliers: forge,streamgl,dask (default: 4,4,1) |
| `-p, --preset <name>` | Use hardware preset (140+ available) |
| `-E, --export [FILE]` | Export env vars (stdout or append to file) |
| `-l, --list-presets` | List all available presets |
| `-h, --help` | Show help message |

## Replication Model

The wizard uses a simple replication model:

```
Total workers = N GPUs x multiplier
```

**Default multipliers** (per GPU):
- forge-etl-python: 4 workers
- streamgl-gpu: 4 workers
- dask-cuda-worker: 1 worker

Workers > GPUs is intentional for multi-user concurrent handling:
- Multiple users can run blocking tasks simultaneously
- Cached operations can be served while compute runs
- Round-robin GPU assignment distributes load

## Examples

```bash
# Auto-detect GPUs, use default multipliers
./etc/scripts/gpu-config-wizard.sh

# Use 4 GPUs with default multipliers (16 forge, 16 streamgl, 4 dask)
./etc/scripts/gpu-config-wizard.sh -n 4

# Use specific GPUs with custom multipliers
./etc/scripts/gpu-config-wizard.sh -g 2,3,5-7 -w 2,2,1

# Simulate DGX A100 configuration
./etc/scripts/gpu-config-wizard.sh -p dgx-a100

# AWS p3.8xlarge preset with custom multipliers
./etc/scripts/gpu-config-wizard.sh -p aws-p3-8xlarge -w 2,2,1

# Print configuration to stdout (for copying)
./etc/scripts/gpu-config-wizard.sh -p dgx-a100 -E

# Export configuration directly to custom.env file
./etc/scripts/gpu-config-wizard.sh -p dgx-a100 -E ./data/config/custom.env
```

## Hardware Presets

### NVIDIA DGX Systems

| Preset | GPUs | Description |
|--------|------|-------------|
| `dgx-a100` | 8 | NVIDIA DGX A100 (8x A100 80GB) |
| `dgx-h100` | 8 | NVIDIA DGX H100 (8x H100 80GB) |
| `dgx-station-a100` | 4 | NVIDIA DGX Station A100 (4x A100 80GB) |
| `dgx-1` | 8 | NVIDIA DGX-1 (8x V100 32GB) |
| `dgx-2` | 16 | NVIDIA DGX-2 (16x V100 32GB) |
| `dgx-spark` | 1 | NVIDIA DGX Spark ARM (1x GB200 128GB) |
| `dgx-b200` | 8 | NVIDIA DGX B200 (8x B200 192GB) |

### NVIDIA Grace Hopper / Blackwell

| Preset | GPUs | Description |
|--------|------|-------------|
| `gh200` | 1 | NVIDIA GH200 Grace Hopper ARM (1x GH200 96GB) |
| `gh200-nvl` | 2 | NVIDIA GH200 NVL ARM (2x GH200 96GB) |
| `gb200-nvl2` | 2 | NVIDIA GB200 NVL2 ARM (2x GB200 384GB) |
| `gb200-nvl72` | 72 | NVIDIA GB200 NVL72 ARM (72x GB200 13.5TB total) |
| `hgx-b200` | 8 | NVIDIA HGX B200 (8x B200 192GB) |
| `hgx-b100` | 8 | NVIDIA HGX B100 (8x B100 192GB) |

### AWS EC2 Instances

| Preset | GPUs | Description |
|--------|------|-------------|
| `aws-p5.48xlarge` | 8 | AWS p5.48xlarge (8x H100 80GB) |
| `aws-p4d.24xlarge` | 8 | AWS p4d.24xlarge (8x A100 40GB) |
| `aws-p4de.24xlarge` | 8 | AWS p4de.24xlarge (8x A100 80GB) |
| `aws-p3.16xlarge` | 8 | AWS p3.16xlarge (8x V100 16GB) |
| `aws-p3.8xlarge` | 4 | AWS p3.8xlarge (4x V100 16GB) |
| `aws-p3.2xlarge` | 1 | AWS p3.2xlarge (1x V100 16GB) |
| `aws-g5.xlarge` | 1 | AWS g5.xlarge (1x A10G 24GB) |
| `aws-g5.12xlarge` | 4 | AWS g5.12xlarge (4x A10G 24GB) |
| `aws-g5.48xlarge` | 8 | AWS g5.48xlarge (8x A10G 24GB) |
| `aws-g4dn.xlarge` | 1 | AWS g4dn.xlarge (1x T4 16GB) |
| `aws-g4dn.12xlarge` | 4 | AWS g4dn.12xlarge (4x T4 16GB) |
| `aws-g5g.xlarge` | 1 | AWS g5g.xlarge Graviton2 ARM (1x T4 16GB) |
| `aws-g5g.16xlarge` | 2 | AWS g5g.16xlarge Graviton2 ARM (2x T4 16GB) |
| `aws-g5g.metal` | 2 | AWS g5g.metal Graviton2 ARM (2x T4 16GB) |

### Microsoft Azure

| Preset | GPUs | Description |
|--------|------|-------------|
| `azure-nd96asr-v4` | 8 | Azure ND96asr v4 (8x A100 40GB) |
| `azure-nd96amsr-a100-v4` | 8 | Azure ND96amsr A100 v4 (8x A100 80GB) |
| `azure-nd96isr-h100-v5` | 8 | Azure ND96isr H100 v5 (8x H100 80GB) |
| `azure-nc24ads-a100-v4` | 1 | Azure NC24ads A100 v4 (1x A100 80GB) |
| `azure-nc48ads-a100-v4` | 2 | Azure NC48ads A100 v4 (2x A100 80GB) |
| `azure-nc96ads-a100-v4` | 4 | Azure NC96ads A100 v4 (4x A100 80GB) |
| `azure-nc6s-v3` | 1 | Azure NC6s v3 (1x V100 16GB) |
| `azure-nc12s-v3` | 2 | Azure NC12s v3 (2x V100 16GB) |
| `azure-nc24s-v3` | 4 | Azure NC24s v3 (4x V100 16GB) |
| `azure-nc4as-t4-v3` | 1 | Azure NC4as T4 v3 (1x T4 16GB) |
| `azure-nc64as-t4-v3` | 4 | Azure NC64as T4 v3 (4x T4 16GB) |
| `azure-nv6ads-a10-v5` | 1 | Azure NV6ads A10 v5 (1x A10 4GB, 1/6 GPU) |
| `azure-nv36ads-a10-v5` | 1 | Azure NV36ads A10 v5 (1x A10 24GB) |
| `azure-nv72ads-a10-v5` | 2 | Azure NV72ads A10 v5 (2x A10 24GB) |
| `azure-ncads-h100-v5` | 1 | Azure NCads H100 v5 ARM (1x H100 80GB) |

### Google Cloud Platform

| Preset | GPUs | Description |
|--------|------|-------------|
| `gcp-a2-highgpu-1g` | 1 | GCP a2-highgpu-1g (1x A100 40GB) |
| `gcp-a2-highgpu-2g` | 2 | GCP a2-highgpu-2g (2x A100 40GB) |
| `gcp-a2-highgpu-4g` | 4 | GCP a2-highgpu-4g (4x A100 40GB) |
| `gcp-a2-highgpu-8g` | 8 | GCP a2-highgpu-8g (8x A100 40GB) |
| `gcp-a2-megagpu-16g` | 16 | GCP a2-megagpu-16g (16x A100 40GB) |
| `gcp-a2-ultragpu-1g` | 1 | GCP a2-ultragpu-1g (1x A100 80GB) |
| `gcp-a2-ultragpu-2g` | 2 | GCP a2-ultragpu-2g (2x A100 80GB) |
| `gcp-a2-ultragpu-4g` | 4 | GCP a2-ultragpu-4g (4x A100 80GB) |
| `gcp-a2-ultragpu-8g` | 8 | GCP a2-ultragpu-8g (8x A100 80GB) |
| `gcp-a3-highgpu-8g` | 8 | GCP a3-highgpu-8g (8x H100 80GB) |
| `gcp-n1-t4-1` | 1 | GCP n1-standard (1x T4 16GB) |
| `gcp-n1-t4-4` | 4 | GCP n1-standard (4x T4 16GB) |
| `gcp-g2-standard-4-arm` | 1 | GCP g2-standard-4 ARM (1x L4 24GB) |
| `gcp-g2-standard-16-arm` | 2 | GCP g2-standard-16 ARM (2x L4 24GB) |

### Oracle Cloud Infrastructure

| Preset | GPUs | Description |
|--------|------|-------------|
| `oci-bm-gpu-a100-4` | 4 | OCI BM.GPU.A100-v2.8 (4x A100 40GB) |
| `oci-bm-gpu-h100-8` | 8 | OCI BM.GPU.H100.8 (8x H100 80GB) |
| `oci-bm-gpu-a10-4` | 4 | OCI BM.GPU.A10.4 (4x A10 24GB) |
| `oci-vm-gpu-a10-1` | 1 | OCI VM.GPU.A10.1 (1x A10 24GB) |
| `oci-vm-gpu-a10-2` | 2 | OCI VM.GPU.A10.2 (2x A10 24GB) |
| `oci-bm-gpu-a10-4-arm` | 4 | OCI BM.GPU.A10.4 ARM (4x A10 24GB) |

### Lambda Labs

| Preset | GPUs | Description |
|--------|------|-------------|
| `lambda-1xa100` | 1 | Lambda Labs (1x A100 40GB) |
| `lambda-2xa100` | 2 | Lambda Labs (2x A100 40GB) |
| `lambda-4xa100` | 4 | Lambda Labs (4x A100 40GB) |
| `lambda-8xa100` | 8 | Lambda Labs (8x A100 40GB) |
| `lambda-1xh100` | 1 | Lambda Labs (1x H100 80GB) |
| `lambda-8xh100` | 8 | Lambda Labs (8x H100 80GB) |
| `lambda-1xa10` | 1 | Lambda Labs (1x A10 24GB) |
| `lambda-4xa6000` | 4 | Lambda Labs (4x RTX A6000 48GB) |

### CoreWeave

| Preset | GPUs | Description |
|--------|------|-------------|
| `coreweave-1xa100` | 1 | CoreWeave (1x A100 40GB) |
| `coreweave-1xa100-80` | 1 | CoreWeave (1x A100 80GB) |
| `coreweave-8xa100` | 8 | CoreWeave (8x A100 40GB) |
| `coreweave-1xh100` | 1 | CoreWeave (1x H100 80GB) |

### Workstations

| Preset | GPUs | Description |
|--------|------|-------------|
| `workstation-rtx4090` | 1 | Workstation (1x RTX 4090 24GB) |
| `workstation-rtx4090-2` | 2 | Workstation (2x RTX 4090 24GB) |
| `workstation-a6000` | 1 | Workstation (1x RTX A6000 48GB) |
| `workstation-a6000-2` | 2 | Workstation (2x RTX A6000 48GB) |
| `workstation-a6000-4` | 4 | Workstation (4x RTX A6000 48GB) |

### Consumer / Hobbyist

| Preset | GPUs | Description |
|--------|------|-------------|
| `rtx5090` | 1 | Consumer (1x RTX 5090 32GB) |
| `rtx5090-2` | 2 | Consumer (2x RTX 5090 32GB) |
| `rtx4090` | 1 | Consumer (1x RTX 4090 24GB) |
| `rtx4090-2` | 2 | Consumer (2x RTX 4090 24GB) |
| `rtx4090-4` | 4 | Consumer (4x RTX 4090 24GB) |
| `rtx3090` | 1 | Consumer (1x RTX 3090 24GB) |
| `rtx3090-2` | 2 | Consumer (2x RTX 3090 24GB) |
| `rtx3090-4` | 4 | Consumer (4x RTX 3090 24GB) |
| `hobbyist-8gpu` | 8 | Hobbyist (8x RTX 3090 24GB) |
| `hobbyist-10gpu` | 10 | Hobbyist (10x RTX 3090 24GB) |

### Rack Servers

| Preset | GPUs | Description |
|--------|------|-------------|
| `rack-24gpu` | 24 | Rack server (24x A100 40GB) |
| `rack-32gpu` | 32 | Rack server (32x A100 40GB) |

### Development

| Preset | GPUs | Description |
|--------|------|-------------|
| `dev-single` | 1 | Development (1x RTX 4080 16GB) |
| `dev-dual` | 2 | Development (2x RTX 3060 12GB) |

### Supercomputers

| Preset | GPUs | Description |
|--------|------|-------------|
| `dgx-superpod-h100` | 256 | NVIDIA DGX SuperPOD (32x DGX H100) |
| `dgx-superpod-b200` | 256 | NVIDIA DGX SuperPOD (32x DGX B200) |
| `dgx-basepod-h100` | 32 | NVIDIA DGX BasePOD (4x DGX H100) |
| `xai-colossus` | 100000 | xAI Colossus Supercomputer (100k H100) |
| `meta-rsc` | 16000 | Meta Research SuperCluster (16000x A100 80GB) |
| `microsoft-eagle` | 14400 | Microsoft Eagle Supercomputer (14400x H100 80GB) |

## Generated Configuration

The wizard generates environment variables for `data/config/custom.env`:

```bash
# GPU Assignment (all services share all GPUs)
CUDA_VISIBLE_DEVICES=0,1,2,3

# Worker Configuration (N GPUs x multiplier)
FORGE_NUM_WORKERS=16
STREAMGL_NUM_WORKERS=16
DASK_NUM_WORKERS=4
```

## Applying Configuration

After generating settings:

1. Copy the settings to `data/config/custom.env` (or use `-E` to export directly)
2. Restart GPU services:

```bash
./graphistry up --force-recreate forge-etl-python streamgl-gpu dask-cuda-worker
```

## Fine-Grained Control

For advanced tuning beyond the wizard, set these environment variables directly in `data/config/custom.env`:

**Worker counts:**
- `FORGE_NUM_WORKERS` - forge-etl-python workers
- `STREAMGL_NUM_WORKERS` - streamgl-gpu workers
- `DASK_NUM_WORKERS` - dask-cuda-worker instances

**Per-service GPU assignment:**
- `FEP_CUDA_VISIBLE_DEVICES` - forge-etl-python
- `DCW_CUDA_VISIBLE_DEVICES` - dask-cuda-worker
- `STREAMGL_GPU_CUDA_VISIBLE_DEVICES` - streamgl-gpu
- `DASK_SCHEDULER_CUDA_VISIBLE_DEVICES` - dask-scheduler
- `GAK_PUBLIC_CUDA_VISIBLE_DEVICES` - graph-app-kit-public
- `GAK_PRIVATE_CUDA_VISIBLE_DEVICES` - graph-app-kit-private
- `NOTEBOOK_CUDA_VISIBLE_DEVICES` - notebook

See [Performance Tuning - Multi-GPU](../debugging/performance-tuning.md#multi-gpu-tuning) for detailed configuration guidance.
