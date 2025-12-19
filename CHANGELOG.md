# Changelog

All notable changes to this repo are documented in this file. The Graphistry server is tracked in the main [Graphistry major release history documentation](https://graphistry.zendesk.com/hc/en-us/articles/360033184174-Enterprise-Release-List-Downloads).

The changelog format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and all PyGraphistry-specific breaking changes are explictly noted here.

## [Development]

### Added

* GPU Configuration Wizard documentation (`docs/tools/gpu-config-wizard.md`)
* Environment Variables Reference page (`docs/app-config/environment-variables.md`)
* GPU Memory Watcher documentation in performance tuning

### Changed

* `./graphistry` command documentation clarified as docker compose wrapper with GPU, telemetry, and cluster context
* Updated commands.md with improved docker compose wrapper explanation
* Enhanced performance tuning documentation with GPU memory management
* Updated hardware-software requirements documentation

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
