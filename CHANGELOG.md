# Changelog

All notable changes to this repo are documented in this file. The Graphistry server is tracked in the main [Graphistry major release history documentation](https://graphistry.zendesk.com/hc/en-us/articles/360033184174-Enterprise-Release-List-Downloads).

The changelog format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and all PyGraphistry-specific breaking changes are explictly noted here.

## [Development]

### Added

* GPU Configuration Wizard documentation (`docs/tools/gpu-config-wizard.md`)
* Environment Variables Reference page (`docs/app-config/environment-variables.md`)
* GPU Memory Watcher documentation in performance tuning
* Troubleshooting guide (`docs/debugging/troubleshooting.md`)
* Legacy setup guides subfolder with EOL documentation (`docs/install/on-prem/legacy/`)
* CUDA compatibility matrix and GPU architecture support table in hardware-software.md
* Documentation build wrapper script (`build-docs.sh`) with `--help`, format selection, auto-clean, and error handling

### Changed

* `./graphistry` command documentation clarified as docker compose wrapper with GPU, telemetry, and cluster context
* Updated commands.md with improved docker compose wrapper explanation
* Enhanced performance tuning documentation with GPU memory management
* Updated hardware-software requirements documentation
* OS recommendations updated: Ubuntu 24.04 LTS recommended (22.04, 20.04 also supported), RHEL 8.x/9.x
* Command references updated from `docker-compose` to `./graphistry` wrapper throughout documentation
* Azure manual setup guide updated with modern Ubuntu versions and removed outdated docker-compose download
* AWS setup guide updated with Ubuntu 24.04/22.04 LTS and RHEL 8.x/9.x
* PyGraphistry configuration updated: API v3 (JWT+Arrow) now required, API v1/v2 removed
* Authentication documentation updated with v2 REST API links

### Deprecated

* API v1 VGraph permanently removed (server returns HTTP 410 Gone for `/etl` endpoints)
* Legacy OS setup guides moved to `docs/install/on-prem/legacy/`:
  - Ubuntu 18.04 LTS (EOL April 2023)
  - RHEL 7.6 (Maintenance Support ended June 2024)

### Fixed

* Broken internal links in benchmarking.md (telemetry path corrected)
* User-creation.md reference path in on-prem installation guide
* Orphan file `debugging-front-end.md` added to debugging toctree
* HTTP to HTTPS for external URLs (hub.graphistry.com, github.com, ec2instances.info)
* Microsoft docs URLs updated from docs.microsoft.com to learn.microsoft.com

## [v2.41.8 - 2024-10-27]

### Added

* ReadTheDocs site: [https://graphistry-admin-docs.readthedocs.io/](https://graphistry-admin-docs.readthedocs.io/)
* Python endpoint

### Changed

* Reorganized documentation into thematic areas
* Update RAPIDS base image
* Update RAPIDS Python env name to `base` from `rapids`
* Updated most docker compose command references to `docker compose` from `docker-compose`

### Infra

* Sphinx port
* CI

### Fixed

* Telemetry images
