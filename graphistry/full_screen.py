#!/usr/bin/env python
"""
A simple example of a calculator program.
This could be used as inspiration for a REPL.
"""
from __future__ import unicode_literals

from prompt_toolkit.application import Application
from prompt_toolkit.document import Document
from prompt_toolkit.filters import has_focus
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.layout.containers import HSplit, Window, VSplit
from prompt_toolkit.layout.layout import Layout
from prompt_toolkit.styles import Style
from prompt_toolkit.widgets import TextArea
from widgets import revisionist_commit_history
from prompt_toolkit.shortcuts import set_title
from prompt_toolkit import prompt
import click


help_text = """
Type any expression (e.g. "4 + 4") followed by enter to execute.
Press Control-C to exit.
"""


def main():
    click.secho(" ______     __  __     ______     __         __    ", fg="red")
    click.secho("/\  ___\   /\ \_\ \   /\  ___\   /\ \       /\ \   ", fg="yellow")
    click.secho("\ \ \____  \ \____ \  \ \ \____  \ \ \____  \ \ \  ", fg="green")
    click.secho(" \ \_____\  \/\_____\  \ \_____\  \ \_____\  \ \_\ ", fg="blue")
    click.secho("  \/_____/   \/_____/   \/_____/   \/_____/   \/_/ ", fg="magenta")

    main_prompt = prompt('graphistry>> ', enable_system_prompt=True)




    # The layout.
    output_field = TextArea(style='class:output-field', text=help_text)
    input_field = TextArea(height=2, prompt='graphistry>> ', style='class:input-field')
    bottom_field = TextArea(height=1, style='class:bottom-toolbar', text=revisionist_commit_history())

    main_output = VSplit([
        output_field,
        Window(char='~'),
        Window(width=20, style='class:line'),
    ])
    container = HSplit([
        main_output,
        Window(height=1, char='~', style='class:line'),
        input_field,
        bottom_field
    ])

    # The key bindings.
    kb = KeyBindings()

    @kb.add('c-c')
    @kb.add('c-q')
    def _(event):
        " Pressing Ctrl-Q or Ctrl-C will exit the user interface. "
        event.app.exit()

    @kb.add('enter', filter=has_focus(input_field))
    def _(event):
        try:
            output = '\n\nIn:  {}\nOut: {}'.format(
                input_field.text,
                eval(input_field.text))  # Don't do 'eval' in real code!
        except BaseException as e:
            output = '\n\n{}'.format(e)
        new_text = output_field.text + output

        output_field.buffer.document = Document(
            text=new_text, cursor_position=len(new_text))
        input_field.text = ''

    # Style.
    style = Style([
        ('output-field', 'bg:#000044 #ffffff'),
        ('input-field', 'bg:#000000 #ffffff'),
        ('line',        '#004400'),
        ('bottom-toolbar',      '#000000 #ffffff'),
        ('bottom-toolbar.text', '#ffffff'),
    ])

    # Run application.
    application = Application(
        layout=Layout(container, focused_element=input_field),
        key_bindings=kb,
        style=style,
        mouse_support=True,
        full_screen=True,
        )

    application.run()


if __name__ == '__main__':

    main()