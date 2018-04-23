from config import Graphistry
import json
import docker
import sys
from os.path import expanduser, exists, dirname, join, realpath, isdir
from pathlib import Path
from docker.errors import NotFound
from requests.exceptions import ReadTimeout
from fabric.api import local

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
        docker = self.docker_lowlevel_api()
        if reauth:
            self._g.gcloud_auth()
        click.secho("Pulling Private Images", fg="magenta")
        for image in self.images['private']:
            for line in docker.pull(image, stream=True):
                click.secho(pretty_line(line), fg="magenta")
        click.secho("Pulling Public Images", fg="blue")
        for image in self.images['public']:
            for line in docker.pull(image, stream=True):
                click.secho(pretty_line(line), fg="blue")

    def launch(self):
        import pdb; pdb.set_trace()

    def compile(self):
        """
        Generate dist/graphistry.tar.gz. Run pull beforehand.
        :return:
        """
        images = self.images['public']+self.images['private']
        _docker = self.docker_lowlevel_api()

        try:
            for tag in images:
                print("Saving Image: {0}".format(tag))
                image = _docker.get_image(tag)

            local('docker save -o containers.tar ' + ' '.join(images))
            local('echo -e "#\!/bin/bash\ndocker load -i containers.tar" > load.sh && chmod +x load.sh')

        except NotFound:
            click.secho("Containers not found, use `pull`.", fg="red")


    def load(self):
        _filename = "containers.tar"
        if exists(_filename):
            local("docker load -i containers.tar")
        else:
            click.secho("Container archive not found. Run complie or ask your administrator for one.", fg="red")


        """
        local('docker save -o containers.tar ' + ' '.join(images))
        local('echo -e "#\!/bin/bash\ndocker load -i containers.tar" > load.sh && chmod +x load.sh')
        if not exists('dist'):
            local('mkdir dist')
            click.secho('Compiling Distrobution Bundle [dist/graphistry.tar.gz]. This will take a a few minutes.', fg='yellow')
        tls = isdir('ssl')
        maybe_ssl = ' ssl' if tls else ''

        cmd = "touch dist/graphistry.tar.gz && " \
              "tar -czf dist/graphistry.tar.gz ./deploy/launch.sh " \
              "httpd-config.json load.sh pivot-config.json " \
              "viz-app-config.json containers.tar'"
        local(cmd + maybe_ssl)
        """
