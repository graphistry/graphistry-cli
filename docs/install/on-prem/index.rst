On-Prem Installation
========================

.. toctree::
  :maxdepth: 1

  manual
  vGPU
  legacy/index



Quick launch: Manual
------------------------

Requirements: `Download Graphistry <https://graphistry.zendesk.com/hc/en-us/articles/360033184174>`_ and :ref:`verify Docker is set up with Nvidia runtime as default <quick-testing-and-test-gpu>`

**1. Install** if not already available from the folder with ``containers.tar.gz``, and likely using ``sudo``:

.. code-block:: bash

   docker load -i containers.tar.gz

Note: In previous versions (< ``v2.35``), the file was ``containers.tar``


**2. Launch** from the Graphistry folder using the ``./graphistry`` wrapper (wraps docker compose), likely using ``sudo``:

.. code-block:: bash

   ./graphistry up -d

Note: Takes 1-3 min, and around 5 min, ``docker ps`` should report all services as ``healthy``

**3. Test:**  Go to

.. code-block:: text

   http://localhost

* Create an account, and then try running a prebuilt Jupyter Notebook from the dashboard!

  * The first account gets an admin role, upon which account self-registration closes. Admins can then invite users or open self-registration. See :doc:`User Creation </tools/user-creation>` for more information.

* Try a visualization like http://localhost/graph/graph.html?dataset=Facebook&play=5000&splashAfter=false

  * **Warning**: First viz load may be slow (1 min) as RAPIDS generates **just-in-time** code for each GPU worker upon first encounter, and/or require a page refresh

Manual enterprise install
-------------------------

NOTE: Managed Graphistry instances do not require any of these steps.

The Graphistry environment depends solely on `Nvidia RAPIDS <https://rapids.ai>`_ and `Nvidia Docker <https://github.com/NVIDIA/nvidia-docker>`_ via ``Docker Compose 3``, and ships with all other dependencies built in.
