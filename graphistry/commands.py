from graphistry.config import Graphistry
from graphistry.cluster import Cluster
import sys, click

__Commands__ = ['init', 'login', 'config', 'pull', 'launch', 'load', 'compile', 'update', 'stop', 'help', 'exit']
__CommandsMeta__ = {
    'init': 'Configure and Launch Graphistry',
    'login': 'Login to Graphistry',
    'config': 'Configure Graphistry',
    'launch': 'Launch Graphistry',
    'pull': 'Pull docker contgainers',
    'compile': 'Generate dist/graphistry.tar.gz',
    'load': 'Load Graphistry from Container Archive',
    'stop': 'Stop All Graphistry Containers',
    'help': 'Shows all CLI commands',
    'exit': 'Leave application. Ctrl-C or Ctrl-D works too.',
}

def init():
    _g = Graphistry()
    _g.create_bcrypt_container()
    _g.login()
    _g.save_config()
    _g.template_config()

    _c = Cluster()
    _c.pull()
    _c.launch()


def login():
    _g = Graphistry()
    _g.login()
    _g.save_config()


def config():
    _g = Graphistry()
    _g.template_config()


def config_offline():
    _g = Graphistry()
    _g.template_config(airgapped=True)


def pull():
    _c = Cluster()
    _c.pull()


def launch():
    _c = Cluster()
    _c.launch()


def load():
    _c = Cluster()
    _c.load()


def compile():
    _c = Cluster()
    _c.compile()

def compile_with_config():
    _c = Cluster()
    _c.compile(include_config=True)


def update():
    _g = Graphistry()
    _g.login()
    _g.save_config()


def stop():
    _c = Cluster()
    _c.stop()


def help():
    for k,v in __CommandsMeta__.items():
        click.secho("{0}: {1}".format(k,v), fg='yellow')


def exit():
    sys.exit()
