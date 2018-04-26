from __future__ import unicode_literals

from prompt_toolkit import prompt

from graphistry.widgets import revisionist_commit_history_html
from graphistry.menus import MainNav
from graphistry.commands import __Commands__

import click


@click.command()
@click.option('--headless', '-h', multiple=True)
def main(headless=None):
    while True:
        toolbar_message = revisionist_commit_history_html()

        try:
            if not headless:
                select = prompt('graphistry>> ',
                                completer=MainNav().get_completer(),
                                bottom_toolbar=toolbar_message,
                                complete_while_typing=True,
                                history=None)
            else:
                select = headless

            if select in __Commands__:
                cmd = MainNav.get_command(select)
                cmd()

        except EOFError:
            break  # Control-D pressed.
        except KeyboardInterrupt:
            break


if __name__ == '__main__':
    main()
