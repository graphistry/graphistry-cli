
# FAQ

* Where are the docs? See this [GitHub repository](https://github.com/graphistry/graphistry-cli) for admin docs and [Graphistry Hub docs](http://hub.graphistry.com/docs) (or http://your_graphistry/docs) for analyst and developer docs

* Where do I get help? Whether community chat, email, tickets, a call, or even a training, [pick the most convienent option](https://www.graphistry.com/support)

* Can Graphistry run in the cloud? Yes - privately both via a [preconfigured AWS/Azure marketplace](https://www.graphistry.com/get-started) and as a self-managed docker binary. Contact our team for upcoming managed Graphistry Hub cloud tiers.

* Can Graphistry run privately? 
  * On-prem, including air-gapped, as a team backend server or a Linux-based analyst workstation, via docker image
  * Cloud, via prebuilt marketplace instance
  * Cloud, via docker image
  
* Can Graphistry run in ...
  * A VM: [Yes, including VMWare vSphere, Nutanix AHV, and anywhere else Nvidia RAPIDS.ai runs](install/on-prem/vGPU.md). Just set `RMM_ALLOCATOR=default` in your `data/config/custom.env` to avoid relying on CUDA Unified Memory, which vGPUs do not support.
  * Ubuntu / Red Hat / ... : Yes, just ensure the Nvidia Docker runtime is set as the default for docker-compose. We can assist with reference environment bootstrap scripts.
  * Podman: Maybe! We have confirmed our core containers run on RHEL 8.3 with Podman, Nvidia container runtime, and docker-compose cli. Please contact our staff for the possibility of an alternate podman-compatible tarball. 
  
* How do I do license management? 
  * Graphistry does not require software-managed license registration, we can work with your procurement team on self-reported use

* Do I need a GPU on the client? No, clients do not need a GPU. They do need WebGL enabled, such as Chrome's non-GPU software emulation mode. If some of your users are on extremely limited environments, e.g., worse than a modern phone, or you have extremely powerful GPUs you would like to share, users report great experiences with GPU VDI technologies.

* Do I need a GPU on the server? Yes, the server requires an Nvidia GPU that is Pascal or later (T4, P100, V100, A100, RTX, ...). 

* Can Graphistry use multiple GPUs and multiple servers? 
  * Graphistry visualizations take advantage of multiple GPUs & CPUs on the same server to handle more users
  * Graphistry-managed Jupyter notebooks enable users to run custom GPU code, where each user may run multi-GPU tasks (e.g., via dask-cudf and dask-sql)
  * For high availability configuration and operation, contact staff for additional guidance
  * For many-node deployment and multi-GPU visualization acceleration, contact staff for roadmap

* Can I run multiple instances of Graphistry? Yes, see the command section for running in an isolated namespace. This is primarily for testing and in-place upgrading. If your goal is for Graphistry to use multiple CPUs and GPUs, it already does so automatically, so you can launch as usual.

* Can I use Graphistry from OS X / Windows? Yes, analysts can use any modern browser on any modern OS such as Chrome on Windows and Firefox on OS X, and even on small devices like Android phones and Apple tablets. The server requires Linux (Ubuntu, RHEL, ...) with a GPU. A self-contained analyst workstation would be Linux based.

* How do I try it out?
  * Notebook/API users can get a free account on [Graphistry Hub](https://www.graphistry.com/get-started)
  * Interact with pregenerated live visualizations on the [PyGraphistry gallery](https://github.com/graphistry/pygraphistry)
  * If you have a private sample CSV/XLS/etc., you can [spin up a private server in your AWS/Azure account](https://www.graphistry.com/get-started) and turn it off when done, and [our team is happy to help](https://www.graphistry.com/support)

* How can I test if my GPU supports Graphistry and my GPU environment is setup properly? Graphistry only requires a [RAPIDS-compatible](https://www.rapids.ai) Docker environment, so you can use the community resources for that. In addition, see [Testing an Install](install/testing-an-install.md).

* The server is slow to start, is it broken?
  * The server may take 1-3min to start; check the health status of each service with `sudo docker ps`
  * By default, Graphistry has 4 RAPIDS workers (service `etl-server-python`) that perform just-in-time GPU compilation, meaning the first load on each is slow.
  * ... System start and the first visualization load per process might be sped up by ensuring Docker is using a native diff driver (see [performance tuning](debugging/performance-tuning.md))
  * ... Subsequent use of those workers are fast for new datasets (code is already compiled), and subsequent reloads of recent datasets are extra fast (cached)

* Can I add extra security layers? Yes -- see the hardening section for configuring areas like TLS, and contact the team for assistance with more custom/experimental layers like SSO

* Can I run on another port? Yes -- modify `docker-compose.yml`'s service `caddy:`, such as for 80 to instead be 8888:
```yaml
    ports:
      - 8888:80
    expose:
      - "8888"
```