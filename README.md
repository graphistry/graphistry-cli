# Welcome to Graphistry: Admin Guide

Graphistry is the most scalable graph-based visual analysis and investigation automation platform. It supports both cloud and on-prem deployment options. Big graphs are tons of fun!

The documentation here covers system administration

See bottom of page for table of contents and additional resources.

## Get

Pick an a configuration:
* Graphistry Hub: Graphistry manages Hub for its users
* AWS/Azure Marketplace: See cloud install instructions
* Docker (self-hosted): See [enterprise release portal](https://graphistry.zendesk.com/hc/en-us/articles/360033184174)
* Experimental - Kubernetes Helm chart: See [graphistry/graphistry-helm repository](https://github.com/graphistry/graphistry-helm)

## Learn

See [user and developer documentation](https://hub.graphistry.com/docs)



## Quick GPU Docker environment test

You can test your GPU environment via Graphistry's [base RAPIDS Docker image on DockerHub](https://hub.docker.com/r/graphistry/graphistry-forge-base):

```bash
docker run --rm -it --entrypoint=/bin/bash graphistry/graphistry-forge-base:latest -c "source activate rapids && python3 -c \"import cudf; print(cudf.DataFrame({'x': [0,1,2]})['x'].sum())\""
```

=>
```
3
```

See the installation and debugging sections for additional scenarios such as ensuring Docker Compose is correctly defaulting to a GPU runtime.


## Further reading

* [Release portal](https://graphistry.zendesk.com/hc/en-us/articles/360033184174) for enterprise admins to download the latest
* [Release notes](https://graphistry.zendesk.com/hc/en-us/articles/360033184174)
* [Main documentation](https://hub.graphistry.com/docs) or the same URL adjusted for your local server's address
