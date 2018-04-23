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

Launch a GPU instance of Graphistry of either RHEL or Ubuntu

ssh into the graphistry instance and clone this repo

    $ git clone https://github.com/graphistry/graphistry-cli.git
    $ bash graphistry-cli/ubuntu.sh

`graphistry-cli` is currently not a public repo, so you'll need to use your github credentials to get the repo.

This will bootstrap your system and get the graphistry cli ready. This will take a while.

After it completes follow the instructions and run `graphistry`

Inside the graphistry prompt you can hit `tab` to see your options, but all you need to do to get graphistry up and running
is run the `init` command and answer the questions.

Building a Bundled Deploy
-------------------------
From the `graphistry` prompt, type `compile`. Use `load` to load the system.

Troubleshooting:
----------------

Did you have issues with pulling containers and you know they are public? Sometimes `docker-py` gets confused if you have
old containers or are running out of space. Clear out your containers, do a `docker logout` in your terminal and then try again.

Thanks:
-------

A special thanks to `Jonathan Slenders <https://twitter.com/jonathan_s>`_ for
creating `Python Prompt Toolkit <http://github.com/jonathanslenders/python-prompt-toolkit>`_,
which is quite literally the backbone library, that made this app possible.
And the people who made `pgcli <https://github.com/dbcli/pgcli>`_ which I mostly wholesale copied to make this tool

`Click <http://click.pocoo.org/>`_ is used for command line option parsing
and printing error messages.

