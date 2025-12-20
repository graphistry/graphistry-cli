Legacy Setup Guides
===================

.. warning::

   These guides are for **end-of-life operating systems** and are kept for historical reference only.

   **Do not use these for new deployments.**

   For current deployments, use:

   * **Ubuntu 24.04/22.04/20.04**: See ``etc/scripts/bootstrap/`` in your Graphistry distribution
   * **RHEL 8.x/9.x**: See ``etc/scripts/bootstrap/`` or ``rhel8_prereqs_install.sh`` in docs


Ubuntu 18.04 LTS (Bionic Beaver)
--------------------------------

**End of Life**: April 2023 (Standard Support), April 2028 (ESM for Ubuntu Pro only)

**Why deprecated**:

* No longer receives free security updates from Canonical
* NVIDIA drivers and CUDA toolkits no longer tested against Ubuntu 18.04
* Docker and containerd have dropped official Ubuntu 18.04 support
* Guide references outdated components: CUDA 10.2, Driver 430.26, docker-compose 1.24.1

**Migration path**: Upgrade to Ubuntu 22.04 LTS or 24.04 LTS


RHEL 7.6
--------

**End of Life**:

* RHEL 7 Maintenance Support ended June 30, 2024
* RHEL 7 Extended Life Cycle Support (ELS) available until June 30, 2028 (paid add-on)

**Why deprecated**:

* RHEL 7.x uses older kernel (3.10) incompatible with modern NVIDIA drivers (535+)
* NVIDIA RAPIDS no longer supports RHEL 7.x
* Guide references outdated components: RAPIDS 0.7, Driver 430.40, docker-compose 1.24.1
* CentOS 7 (RHEL 7 derivative) reached EOL June 30, 2024

**Migration path**: Upgrade to RHEL 8.x or 9.x


.. toctree::
   :maxdepth: 1
   :caption: Legacy Guides

   ubuntu_18_04_lts_setup
   rhel_7_6_setup
