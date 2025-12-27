# Welcome to Graphistry: Admin Guide

Graphistry is the most scalable graph-based visual analysis and investigation automation platform. It supports both cloud and on-prem deployment options. Big graphs are tons of fun!


## Quick administration links

* [Top commands](https://graphistry-admin-docs.readthedocs.io/en/latest/commands.html)
* [Plan deployments](https://graphistry-admin-docs.readthedocs.io/en/latest/planning/hardware-software.html)
* Install: [Cloud](https://graphistry-admin-docs.readthedocs.io/en/latest/install/cloud/index.html) & [On-prem](https://graphistry-admin-docs.readthedocs.io/en/latest/install/on-prem/index.html)
* [Configure](https://graphistry-admin-docs.readthedocs.io/en/latest/app-config/index.html)
* [Debugging & performance](https://graphistry-admin-docs.readthedocs.io/en/latest/debugging/index.html)
* [Security](https://graphistry-admin-docs.readthedocs.io/en/latest/security/index.html)
* [Operations & tools](https://graphistry-admin-docs.readthedocs.io/en/latest/tools/index.html)
* [Scripts reference](https://graphistry-admin-docs.readthedocs.io/en/latest/tools/scripts-reference.html)
* [FAQ](https://graphistry-admin-docs.readthedocs.io/en/latest/faq/index.html) & [support options](https://graphistry-admin-docs.readthedocs.io/en/latest/support.html)

## Further reading

* [Main Graphistry documentation](https://hub.graphistry.com/docs) and same path on your local server
* [Release portal](https://graphistry.zendesk.com/hc/en-us/articles/360033184174) for enterprise admins to download the latest
* [Release notes](https://graphistry.zendesk.com/hc/en-us/articles/360033184174)
* [Graphistry Hub](https://hub.graphistry.com): Graphistry-managed GPU servers, including free and team tiers
* Docker (self-hosted): See [enterprise release portal](https://graphistry.zendesk.com/hc/en-us/articles/360033184174)
* [Kubernetes Helm charts](https://github.com/graphistry/graphistry-helm) - Experimental


## Quick GPU Docker environment test

You can test your GPU environment via Graphistry's [base RAPIDS Docker image on DockerHub](https://hub.docker.com/r/graphistry/graphistry-forge-base):

```bash
docker run --rm -it --entrypoint=/bin/bash graphistry/graphistry-forge-base:latest -c "source activate base && python3 -c \"import cudf; print(cudf.DataFrame({'x': [0,1,2]})['x'].sum())\""
```

=>
```
3
```

See the installation and debugging sections for additional scenarios such as ensuring Docker Compose is correctly defaulting to a GPU runtime.


