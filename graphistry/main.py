from __future__ import unicode_literals

from prompt_toolkit import prompt

from graphistry.widgets import revisionist_commit_history_html
from graphistry.menus import MainNav
from graphistry.commands import __Commands__, __CommandsMeta__

import click


@click.command()
@click.option('--headless', '-h')
def main(headless=''):
    if headless:
        click.secho(__CommandsMeta__[headless], fg='yellow')
        if headless in __Commands__:
            cmd = MainNav.get_command(headless)
            cmd()
    else:
        while True:
            toolbar_message = revisionist_commit_history_html()

            try:
                select = prompt('graphistry>> ',
                                completer=MainNav().get_completer(),
                                bottom_toolbar=toolbar_message,
                                complete_while_typing=True,
                                history=None)

                if select in __Commands__:
                    cmd = MainNav.get_command(select)
                    cmd()
            except EOFError:
                break  # Control-D pressed.
            except KeyboardInterrupt:
                break


if __name__ == '__main__':
    main()
