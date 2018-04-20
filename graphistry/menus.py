import importlib

from prompt_toolkit.contrib.completers import WordCompleter



class MainNav(object):
    """
    This is the main navigation, services collection, and word auto-completer.
    """
    def __init__(self):
        #: The compiled string for navigation
        self.completer = None

        # get a base set of commands, add some new ones.
        nav = []

        self.autocomplete = {
            'nav': nav,
            'base': ['home', 'help', 'docker', 'login', 'exit']
        }
        self.meta_dict = {
            'home': 'Back to main menu.',
            'help': 'Show help text.',
            'docker': 'do docker stuff',
            'login': 'Login to Graphistry',
            'pull': 'Pull docker contgainers',
            'compile': 'Generate dist/graphistry.tar.gz',
            'exit': 'Leave application. Ctrl-C or Ctrl-D works too.',
        }

        self.nav = self.autocomplete['nav']+self.autocomplete['base']

    def get_completer(self, location=None):
        if location:
            del self.nav[location]
        self.completer = WordCompleter(self.nav, meta_dict=self.meta_dict, ignore_case=True)
        return self.completer

    @staticmethod
    def get_service(service):
        return importlib.import_module("lethe.services."+service)

    def do_prompt(self, prompt):
        return self.autocomplete
