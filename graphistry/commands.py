from graphistry.config import Graphistry
from graphistry.cluster import Cluster
import sys

__Commands__ = ['init', 'login', 'config', 'pull', 'launch', 'load', 'compile', 'update', 'exit']
__CommandsMeta__ = {
    'init': 'Configure and Launch Graphistry',
    'login': 'Login to Graphistry',
    'config': 'Configure Graphistry',
    'launch': 'Launch Graphistry',
    'pull': 'Pull docker contgainers',
    'compile': 'Generate dist/graphistry.tar.gz',
    'load': 'Load Graphistry from Container Archive',
    'exit': 'Leave application. Ctrl-C or Ctrl-D works too.',
}


def init():
    _g = Graphistry()
    _g.create_bcrypt_container()
    _g.login()
    _g.save_config()
    _g.template_config()

    _c = Cluster()
    _c.launch()


def login():
    _g = Graphistry()
    _g.login()
    _g.save_config()


def config():
    _g = Graphistry()
    _g.template_config()


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


def update():
    _g = Graphistry()
    _g.login()
    _g.save_config()


def exit():
    sys.exit()