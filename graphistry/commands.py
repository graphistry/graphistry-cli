from graphistry.config import Graphistry
from graphistry.cluster import Cluster
import sys, click

__Commands__ = ['init', 'login', 'config', 'pull', 'launch', 'load', 'compile', 'update', 'stop', 'exit']
__CommandsMeta__ = {
    'init': 'Configure and Launch Graphistry',
    'login': 'Login to Graphistry',
    'config': 'Configure Graphistry',
    'launch': 'Launch Graphistry',
    'pull': 'Pull docker contgainers',
    'compile': 'Generate dist/graphistry.tar.gz',
    'load': 'Load Graphistry from Container Archive',
    'stop': 'Stop All Graphistry Containers',
    'exit': 'Leave application. Ctrl-C or Ctrl-D works too.',
}


@click.command()
def init():
    _g = Graphistry()
    _g.create_bcrypt_container()
    _g.login()
    _g.save_config()
    _g.template_config()

    _c = Cluster()
    _c.launch()

@click.command()
def login():
    _g = Graphistry()
    _g.login()
    _g.save_config()

@click.command()
def config():
    _g = Graphistry()
    _g.template_config()

@click.command()
def pull():
    _c = Cluster()
    _c.pull()

@click.command()
def launch():
    _c = Cluster()
    _c.launch()

@click.command()
def load():
    _c = Cluster()
    _c.load()

@click.command()
def compile():
    _c = Cluster()
    _c.compile()

@click.command()
def update():
    _g = Graphistry()
    _g.login()
    _g.save_config()

@click.command()
def stop():
    _c = Cluster()
    _c.stop()

@click.command()
def exit():
    sys.exit()
