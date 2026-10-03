"""Build-level regression tests for mixed Markdown/RST documentation."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


DOCS = Path(os.environ.get("DOCS_SOURCE", Path(__file__).resolve().parents[1] / "docs"))


class MarkupLintTests(unittest.TestCase):
    def build(self, text, suffix="rst", extra=None, production=False, docname="index"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            if production:
                shutil.copy2(DOCS / "conf.py", root / "conf.py")
                shutil.copytree(DOCS / "_ext", root / "_ext")
            else:
                (root / "conf.py").write_text(
                    f"import sys\nsys.path.insert(0, {str(DOCS / '_ext')!r})\n"
                    "extensions = ['myst_parser', 'markup_lint']\n"
                    f"master_doc = {docname!r}\n"
                    "myst_heading_anchors = 3\n"
                )
            source = root / f"{docname}.{suffix}"
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_text(text)
            for name, content in (extra or {}).items():
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(content)
            result = subprocess.run(
                [sys.executable, "-m", "sphinx", "-b", "html", str(root), str(root / "_build")],
                capture_output=True, text=True,
            )
            html = root / f"_build/{docname}.html"
            return result.returncode, result.stdout + result.stderr, html.read_text() if html.exists() else ""

    def test_rejects_markdown_in_rst(self):
        for text, diagnostic in [
            ("## Manual enterprise install\n", "Markdown heading"),
            ("[Download](https://example.com)\n", "Markdown link"),
            ("[Download](\nhttps://example.com)\n", "Markdown link"),
            ("[Download\nGraphistry](https://example.com)\n", "Markdown link"),
            ("```bash\ndocker load -i containers.tar.gz\n```\n", "Markdown fence"),
            ("~~~bash\necho test\n~~~\n", "Markdown fence"),
            ("* Item\n\n  [Download](https://example.com)\n", "Markdown link"),
            (".. note::\n\n   ## Wrong heading\n", "Markdown heading"),
        ]:
            with self.subTest(text=text):
                code, output, _ = self.build(text)
                self.assertNotEqual(code, 0, output)
                self.assertIn(diagnostic, output)
                self.assertRegex(output, r"index\.rst:\d+:")

    def test_allows_rst_and_intentional_examples(self):
        code, output, html = self.build(
            "Title\n=====\n\n`Download <https://example.com>`_\n\n"
            "Inline ``[label](url)`` and ``## example``.\n\n"
            "Literal ```[label](url)``.\n\n"
            "```[label](url)``\n\n"
            "`````bash``\n\n"
            "Escaped \\[label](url) and \\## example.\n\n"
            ".. code-block:: markdown\n\n   ## Example\n   [label](url)\n   ```bash\n   echo ok\n   ```\n\n"
            "Literal example::\n\n   ## Example\n   [label](url)\n\n"
            ".. A comment with [label](url)\n\n"
            ".. raw:: html\n\n   <pre>[label](url)</pre>\n"
        )
        self.assertEqual(code, 0, output)
        self.assertIn('href="https://example.com"', html)

    def test_allows_markdown_page_and_include(self):
        markdown = "# Markdown\n\n[Download](https://example.com)\n\n```bash\necho ok\n```\n"
        for text, suffix, extra in [
            (markdown, "md", None),
            (".. include:: example.md\n   :parser: myst\n", "rst", {"example.md": markdown}),
        ]:
            with self.subTest(suffix=suffix):
                code, output, html = self.build(text, suffix, extra)
                self.assertEqual(code, 0, output)
                self.assertIn('href="https://example.com"', html)

    def test_production_config_checks_internal_references(self):
        for doc, section, warning in [
            ("target", "target-section", None),
            ("missing", "target-section", "unknown document: 'missing'"),
            ("target", "missing-section", "undefined label: 'missing-section'"),
        ]:
            with self.subTest(doc=doc, section=section):
                code, output, html = self.build(
                    f"Title\n=====\n\n:doc:`Target <{doc}>` and :ref:`Section <{section}>`\n",
                    extra={"target.md": "(target-section)=\n\n# Target\n", "README.md": "# README\n"},
                    production=True,
                )
                self.assertEqual(code, 0, output)
                if warning:
                    self.assertIn(warning, output)
                else:
                    self.assertNotIn("unknown document", output)
                    self.assertNotIn("undefined label", output)
                    self.assertIn('href="target.html"', html)
                    self.assertIn('href="target.html#target-section"', html)

    def test_installation_pages_render(self):
        for page in ["on-prem", "cloud"]:
            with self.subTest(page=page):
                code, output, html = self.build(
                    (DOCS / "install" / page / "index.rst").read_text(),
                    docname=f"install/{page}/index",
                    extra={
                        "install/testing-an-install.md": (DOCS / "install/testing-an-install.md").read_text(),
                        "tools/user-creation.md": (DOCS / "tools/user-creation.md").read_text(),
                    },
                )
                self.assertEqual(code, 0, output)
                if page == "on-prem":
                    self.assertIn('id="manual-enterprise-install"', html)
                    self.assertIn('href="../testing-an-install.html#quick-testing-and-test-gpu"', html)
                    self.assertIn('href="../../tools/user-creation.html"', html)
                    self.assertIn('class="highlight-bash', html)
                    self.assertNotIn("environnment", html)
                    self.assertNotIn("soley", html)
                else:
                    self.assertIn('id="cloud-installation"', html)
                    self.assertIn('href="https://www.graphistry.com/get-started"', html)
                    self.assertIn('href="https://www.graphistry.com/blog/marketplace-tutorial"', html)


if __name__ == "__main__":
    unittest.main()
