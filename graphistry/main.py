from __future__ import unicode_literals

from prompt_toolkit import prompt

from graphistry.widgets import revisionist_commit_history_html
from graphistry.menus import MainNav
from graphistry.config import Graphistry
from graphistry.cluster import Cluster
import sys


def main():
    while True:
        try:
            text = prompt('graphistry>> ', completer=MainNav().get_completer(), bottom_toolbar=revisionist_commit_history_html,
                      complete_while_typing=True, enable_open_in_editor=True, history=None)


            if text == 'login':
                _g = Graphistry()
                _g.login()
                _g.save_config()

            elif text == 'init':
                _g = Graphistry()
                _g.create_bcrypt_container()
                _g.login()
                _g.save_config()
                _g.template_config()

                _c = Cluster()
                _c.launch()

            elif text == 'config':
                _g = Graphistry()
                _g.template_config()

            elif text == 'pull':
                _c = Cluster()
                _c.pull()

            elif text == 'launch':
                _c = Cluster()
                _c.launch()

            elif text == 'load':
                _c = Cluster()
                _c.load()

            elif text == 'compile':
                _c = Cluster()
                _c.compile()

            elif text == 'update':
                _g = Graphistry()
                _g.login()
                _g.save_config()

            elif text == 'exit':
                sys.exit()

        except EOFError:
            break  # Control-D pressed.
        except KeyboardInterrupt:
            break



if __name__ == '__main__':
    main()