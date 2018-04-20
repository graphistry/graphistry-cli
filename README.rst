A CLI for Managing a Graphistry Deployment
------------------------------------------

|Build Status| |CodeCov| |PyPI| |Landscape| |Gitter|

This is a toolkit for launching and managing a graphistry stack on your servers.

Home Page: http://graphistry.com

Quick Start
-----------

If you already know how to install python packages, then you can simply do:

::

    $ pip install -U graphistry-cli

If you don't know how to install python packages, please check the
`detailed instructions`_.

.. _`detailed instructions`: https://github.com/graphistry/graphistry-cli#detailed-installation-instructions

Usage
-----

::

    $ graphistry [config | launch | stop]


Features
--------

The `graphistry` management cli is written using prompt_toolkit_.

* Talk about # TODO
* What This does

.. _prompt_toolkit: https://github.com/jonathanslenders/python-prompt-toolkit
.. _this issue: https://github.com/graphistry/graphistry-cli/issues

Config
------
A config file is automatically created at ``~/.config/graphistry/config`` at first launch.
See the file itself for a description of all available options.


Detailed Installation Instructions:
-----------------------------------



Linux:
======

In depth getting started guide for ``pip`` - https://pip.pypa.io/en/latest/installing.html.

Check if pip is already available in your system.

::

    $ which pip

If it doesn't exist, use your linux package manager to install `pip`. This
might look something like:

::

    $ sudo apt-get install python-pip   # Debian, Ubuntu, Mint etc

    or

    $ sudo yum install python-pip  # RHEL, Centos, Fedora etc


Then you can install graphistry:

::

    $ sudo pip install graphistry



Thanks:
-------

A special thanks to `Jonathan Slenders <https://twitter.com/jonathan_s>`_ for
creating `Python Prompt Toolkit <http://github.com/jonathanslenders/python-prompt-toolkit>`_,
which is quite literally the backbone library, that made this app possible.
And the people who made `pgcli <https://github.com/dbcli/pgcli>`_ which I mostly wholesale copied to make this tool

`Click <http://click.pocoo.org/>`_ is used for command line option parsing
and printing error messages.

