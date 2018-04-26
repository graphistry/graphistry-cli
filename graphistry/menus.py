import importlib

from prompt_toolkit.contrib.completers import WordCompleter
from graphistry.commands import __Commands__, __CommandsMeta__


class MainNav(object):
    """
    This is the main navigation, services collection, and word auto-completer.
    """
    nav = []
    def __init__(self):
        #: The compiled string for navigation
        self.completer = None

        # get a base set of commands, add some new ones.
        nav = []

        self.autocomplete = {
            'nav': nav,
            'base': __Commands__
        }
        self.meta_dict = __CommandsMeta__

        self.nav = self.autocomplete['nav']+self.autocomplete['base']

    def get_completer(self, location=None):
        if location:
            del self.nav[location]
        self.completer = WordCompleter(self.nav, meta_dict=self.meta_dict, ignore_case=True)
        return self.completer

    @staticmethod
    def run_command(cmd):
        m = importlib.import_module("graphistry.commands")
        return getattr(m, cmd)

    def do_prompt(self, prompt):
        return self.autocomplete
