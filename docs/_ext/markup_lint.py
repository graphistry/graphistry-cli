"""Reject Markdown accidentally written as reStructuredText prose.

Inspect parsed prose so code blocks, raw HTML and comments remain valid places
for examples. Use each node's source path to allow MyST includes in RST pages.
This is a focused parser-mismatch check, not a general Markdown style linter.
"""

from pathlib import Path
import re

from docutils import nodes
from sphinx.errors import SphinxError


MARKDOWN_FENCE = re.compile(r"^[ \t]*(?:`{3,}[^`\n]*|~{3,}[^~\n]*)$", re.MULTILINE)

PATTERNS = (
    ("Markdown heading", re.compile(r"^\s*#{1,6}\s+\S", re.MULTILINE)),
    ("Markdown fence", MARKDOWN_FENCE),
    ("Markdown link", re.compile(r"\[[^\]]+\]\([^)]+\)")),
)


def check_markup(app, doctree):
    problems = []
    for node in doctree.findall(lambda n: isinstance(n, (nodes.paragraph, nodes.title))):
        if Path(node.source or "").suffix != ".rst":
            continue
        text = node.rawsource
        # Inline RST examples are intentional, except malformed triple-backtick
        # fences, which Docutils may partially interpret as inline literals.
        for literal in node.findall(nodes.literal):
            if not MARKDOWN_FENCE.match(literal.rawsource):
                text = text.replace(literal.rawsource, " " * len(literal.rawsource))
        # Escaped RST punctuation intentionally displays markup as text.
        text = re.sub(r"\\.", "  ", text)
        for label, pattern in PATTERNS:
            if pattern.search(text):
                problems.append(f"{node.source}:{node.line}: {label} in RST prose")
    if problems:
        raise SphinxError(
            "\n".join(problems)
            + "\nUse RST headings, links and code-block directives, or a .md page."
        )


def setup(app):
    app.connect("doctree-read", check_markup)
    return {"version": "1", "parallel_read_safe": True, "parallel_write_safe": True}
