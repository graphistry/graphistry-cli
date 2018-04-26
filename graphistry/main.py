from __future__ import unicode_literals

from prompt_toolkit import prompt

from graphistry.widgets import revisionist_commit_history_html
from graphistry.menus import MainNav
from graphistry.commands import __Commands__

import click

# Loop through the availible commands and assign them as CLI args
for _c in __Commands__:
    click.option('--{0}'.format(_c), 'select', flag_value=_c)


@click.command()
def main(select=None):
    while True:
        toolbar_message = revisionist_commit_history_html()

        try:
            if not select:
                select = prompt('graphistry>> ',
                                completer=MainNav().get_completer(),
                                bottom_toolbar=toolbar_message,
                                complete_while_typing=True,
                                history=None)

            if select in __Commands__:
                cmd = MainNav.run_command(select)
                cmd()

        except EOFError:
            break  # Control-D pressed.
        except KeyboardInterrupt:
            break


if __name__ == '__main__':
    main()
