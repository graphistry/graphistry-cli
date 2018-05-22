from graphistry.config import Graphistry
import json
import docker
from os.path import expanduser, exists, dirname, join, realpath, isdir
from os import getcwd
from docker.errors import NotFound
from fabric.api import local
from prompt_toolkit import prompt
from graphistry.widgets import revisionist_commit_history_html

from shutil import copyfile


import click

cwd = dir_path = dirname(realpath(__file__))

def pretty_line(line):
    return json.loads(
        json.dumps(
            str(line.decode('utf-8')),
            indent=4
        )
    )


class Cluster(object):
    def __init__(self):
        self._g = Graphistry()
        self._g.load_config()

        cl_priv_file = open(join(cwd, "container_lists/private.txt"))
        cl_pub_file = open(join(cwd, "container_lists/public.txt"))

        self.images = {
            'public': cl_pub_file.read().splitlines(),
            'private': cl_priv_file.read().splitlines()
        }
        self.images['private'].append(self._g.config.vizapp_container.value)
        self.images['private'].append(self._g.config.pivotapp_container.value)

        cl_priv_file.close()
        cl_pub_file.close()

        self.docker = docker.from_env()

    def docker_lowlevel_api(self):
        return docker.APIClient(base_url='unix://var/run/docker.sock')

    def pull(self, reauth=False):
        self._g.registry_auth()
        docker = self.docker_lowlevel_api()
        if reauth:
            self._g.registry_auth()
        click.secho("Pulling Private Images", fg="magenta")
        for image in self.images['private']:
            for line in docker.pull(image, stream=True):
                click.secho(pretty_line(line), fg="magenta")
        click.secho("Pulling Public Images", fg="blue")
        for image in self.images['public']:
            for line in docker.pull(image, stream=True):
                click.secho(pretty_line(line), fg="blue")

    def launch(self):            

        launch_file_source = join(cwd, 'bootstrap/launch.sh')
        launch_file = 'deploy/launch.sh'
        if not exists('deploy'):
            local('mkdir deploy')


        copyfile(launch_file_source, launch_file)

        local("sed -i 's!<VIZAPP_CONTAINER_NAME>!{0}!g' {1}".format(self._g.config.vizapp_container.value, launch_file))
        local("sed -i 's!<PIVOTAPP_CONTAINER_NAME>!{0}!g' {1}".format(self._g.config.pivotapp_container.value, launch_file))


        tls = isdir('ssl')
        ssl_dir = getcwd() + '/ssl'
        local('cd deploy && chmod +x launch.sh')
        if tls:
            local(
                'export SSLPATH="{ssl_path}" && export SSL_SELF_PROVIDED="1" && export SHIPYARD="1" && cd deploy && bash launch.sh'.format(
                    ssl_path=ssl_dir
                ))
        else:
            local('cd deploy && export SHIPYARD="1" && bash launch.sh')

        click.secho("", fg="yellow")
        click.secho("Graphistry Launched. Please Browse to:", fg="yellow")
        click.secho("{0}".format(self._g.config.graphistry_host.value), fg="yellow")

    def compile(self, include_config=False):
        """
        Generate dist/graphistry.tar.gz. Run pull beforehand.
        :return:
        """

        try:
            bcrypt_image = self.docker.images.get('bcrypt:latest')
        except docker.errors.ImageNotFound:
            self._g.create_bcrypt_container()
            
        self.pull()
        images = self.images['public']+self.images['private']+['bcrypt:latest']

        try:
            # Check that images exist so we can build, if not raised NotFound kills the process
            click.secho('[graphistry] Saving Images:', fg='yellow')
            for tag in images:
                click.secho('\t- {0}'.format(tag), fg='yellow')

            # Build dist directory and python wheelhouse
            click.secho('[graphistry] Building Dependency Wheelhouse for CLI', fg='yellow')
            wheelhouse_dir = expanduser('graphistry-cli/wheelhouse')
            if not exists(wheelhouse_dir):
                local('mkdir -p {0}'.format(wheelhouse_dir))
            local('cd graphistry-cli/wheelhouse && pip wheel -r {0}'.format(join(cwd, 'requirements.txt')))

            # Check for TLS state | TODO: We can just check the config boolean
            tls = isdir('ssl')
            maybe_ssl = ' ssl ' if tls else ''

            # Grab the current config to be used on the on-prem deploy if requested
            if include_config:
                click.secho('[graphistry] Copying configuration for distribution.', fg='yellow')
                config = expanduser('~/.config/graphistry/config.json')

                if exists(config):
                    copyfile(config, 'deploy/config.json')
            maybe_config = ' ./deploy/config.json ' if tls else ''

            # Compile the docker containers. This is done last because it takes forever.
            click.secho('[graphistry] Saving containers from docker.', fg='yellow')
            local('docker save -o containers.tar ' + ' '.join(images))
            local('echo -e "#\!/bin/bash\ndocker load -i containers.tar" > load.sh && chmod +x load.sh')

            # Make easy entrypoint into bootstrap script
            click.secho('[graphistry] Make easy entrypoint into bootstrap script.', fg='yellow')
            local('echo -e "#\!/bin/bash\ncd graphistry-cli && bash bootstrap.sh \$1" > bootstrap.sh && chmod +x bootstrap.sh')

            # Build the package
            click.secho("[graphistry] Compiling Distribution Bundle [dist/graphistry.tar.gz]. "
                        "This will take a a few minutes.",
                        fg='yellow')

            if not exists('dist'):
                local('mkdir dist')
            cmd = "touch dist/graphistry.tar.gz && " \
                  "tar --exclude='./graphistry-cli/.git' " \
                  "-czf dist/graphistry.tar.gz ./deploy/launch.sh " \
                  "graphistry-cli " \
                  "bootstrap.sh load.sh containers.tar "
            if include_config:
                cmd = cmd + "httpd-config.json pivot-config.json viz-app-config.json " + maybe_config + " " + maybe_ssl
            local(cmd)

        except NotFound:
            click.secho("Containers not found, use `pull`.", fg="red")

    def load(self):
        if exists("containers.tar"):
            local("docker load -i containers.tar")
        else:
            click.secho("Container archive not found. Run complie or ask your administrator for one.", fg="red")


    def keygen(self):
        """
        Generate API key token based on an inputted tracking identifier. Requires Graphistry to be running.
        :return:
        """

        toolbar_quip = revisionist_commit_history_html()
        click.secho('[graphistry] Generating API key token.', fg='yellow')
        username = prompt('User name or email, no special characters or spaces (enter for autogen): ', bottom_toolbar=toolbar_quip)
        try:
            local('docker exec monolith-network-nginx wget -q -O - "http://vizapp:3000/api/internal/provision?text=%s" ; echo' %(username))        
        except:
            click.secho("ERROR: could not generate API key; is Graphistry running or did you include special characters and spaces?", fg="red")


    def stop(self):
        """
        Stop all running containers
        :return:
        """
        try:
            local('docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)')
        except:
            click.secho("ERROR: could not stop containers; were none running?", fg="red")
