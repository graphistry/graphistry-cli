On-Prem Installation
========================

.. toctree::
  :maxdepth: 1

  manual
  rhel_7_6_setup
  ubuntu_18_04_lts_setup
  vGPU



Quick launch: Manual
------------------------

Requirements: [Download Graphistry](https://graphistry.zendesk.com/hc/en-us/articles/360033184174) and [verify docker-compose is setup for Nvidia runtimes](testing-an-install.md#6-quick-testing-and-test-gpu)

**1. Install** if not already available from the folder with `containers.tar.gz`, and likely using `sudo`:

```bash
docker load -i containers.tar.gz
```

Note: In previous versions (< `v2.35`), the file was `containers.tar`


**2. Launch** from the folder with `docker-compose.yml` if not already up, and likely using `sudo`:

```bash
docker-compose up -d
```

Note: Takes 1-3 min, and around 5 min, `docker ps` should report all services as `healthy`

**3. Test:**  Go to 

```
http://localhost
```

* Create an account, and then try running a prebuilt Jupyter Notebook from the dashboard!
  * The first account gets an admin role, upon which account self-registration closes. Admins can then invite users or open self-registration. See [User Creation](user-creation.md) for more information.

* Try a visualization like http://localhost/graph/graph.html?dataset=Facebook&play=5000&splashAfter=false 
  * **Warning**: First viz load may be slow (1 min) as RAPIDS generates **just-in-time** code for each GPU worker upon first encounter, and/or require a page refresh

---


## Manual enterprise install

NOTE: Managed Graphistry instances do not require any of these steps.

The Graphistry environnment depends soley on [Nvidia RAPIDS](https://rapids.ai) and [Nvidia Docker](https://github.com/NVIDIA/nvidia-docker) via `Docker Compose 3`, and ships with all other dependencies built in.