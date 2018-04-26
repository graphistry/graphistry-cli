from __future__ import unicode_literals

from prompt_toolkit import prompt

from graphistry.widgets import revisionist_commit_history_html
from graphistry.menus import MainNav
from graphistry.commands import __Commands__


def main():
    while True:
        toolbar_message = revisionist_commit_history_html()

        try:
            text = prompt('graphistry>> ',
                          completer=MainNav().get_completer(),
                          bottom_toolbar=toolbar_message,
                          complete_while_typing=True,
                          history=None)

            if text in __Commands__:
                cmd = MainNav.run_command(text)
                print(cmd)
                cmd()

        except EOFError:
            break  # Control-D pressed.
        except KeyboardInterrupt:
            break


if __name__ == '__main__':
    main()
