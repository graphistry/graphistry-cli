from graphistry.config import Graphistry
from graphistry.cluster import Cluster
import sys, click

__CommandsMeta__ = {
    'compile': 'Generate dist/graphistry.tar.gz',
    'compile_with_config': 'Generate dist/graphistry.tar.gz and include local configuration',
    'config': 'Configure Graphistry relative to latest Graphistry online baseline',
    'config_offline': 'Configure Graphistry relative to offline baseline',
    'exit': 'Leave application. Ctrl-C or Ctrl-D works too.',
    'load_investigations': 'Load investigations from configuration.',
    'keygen': 'Create API key token',
    'help': 'Shows all CLI commands',
    'init': 'Download, configure, and launch Graphistry',
    'launch': 'Launch Graphistry based on local containers',
    'load': 'Load Graphistry from Container Archive',
    'login': 'Login to Graphistry',
    'pull': 'Pull docker containers',
    'stop': 'Stop All Graphistry Containers',
}
__Commands__ = list(__CommandsMeta__.keys())


def init():
    _g = Graphistry()
    _g.create_bcrypt_container()
    _g.login()
    _g.save_config()
    _g.template_config()
    _g.load_investigations()

    _c = Cluster()
    _c.pull()
    _c.launch()


def load_investigations():
    _g.load_investigations()


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

def keygen():
    _c = Cluster()
    _c.keygen()

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
