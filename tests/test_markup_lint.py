"""Build-level regression tests for mixed Markdown/RST documentation."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


DOCS = Path(os.environ.get("DOCS_SOURCE", Path(__file__).resolve().parents[1] / "docs"))


class MarkupLintTests(unittest.TestCase):
    def build(self, text, suffix="rst", extra=None, production=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "conf.py").write_text(
                f"import sys\nsys.path.insert(0, {str(DOCS / '_ext')!r})\n"
                "extensions = ['myst_parser', 'markup_lint']\n"
                "master_doc = 'index'\n"
            )
            (root / f"index.{suffix}").write_text(text)
            for name, content in (extra or {}).items():
                (root / name).write_text(content)
            if production:
                (root / "conf.py").write_text(
                    f"exec(compile(open({str(DOCS / 'conf.py')!r}).read(), "
                    f"{str(DOCS / 'conf.py')!r}, 'exec'))\n"
                    f"sys.path.insert(0, {str(DOCS / '_ext')!r})\n"
                )
            result = subprocess.run(
                [sys.executable, "-m", "sphinx", "-b", "html", str(root), str(root / "_build")],
                capture_output=True, text=True,
            )
            html = root / "_build/index.html"
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

    def test_production_config_allows_internal_rst_links(self):
        code, output, html = self.build(
            "Title\n=====\n\n`Target <target.html>`_\n",
            extra={"target.rst": "Target\n======\n", "README.md": "# README\n"},
            production=True,
        )
        self.assertEqual(code, 0, output)
        self.assertIn('href="target.html"', html)

    def test_gpu_link_fragment_exists(self):
        code, output, html = self.build((DOCS / "install/testing-an-install.md").read_text(), "md")
        self.assertEqual(code, 0, output)
        self.assertIn('id="quick-testing-and-test-gpu"', html)

    def test_installation_pages_render(self):
        for page in ["on-prem", "cloud"]:
            with self.subTest(page=page):
                code, output, html = self.build((DOCS / "install" / page / "index.rst").read_text())
                self.assertEqual(code, 0, output)
                self.assertNotIn("[AWS and Azure marketplaces]", html)
                if page == "on-prem":
                    self.assertIn('id="manual-enterprise-install"', html)
                    self.assertIn('href="../testing-an-install.html#quick-testing-and-test-gpu"', html)
                    self.assertIn('href="../../tools/user-creation.html"', html)
                    self.assertIn('class="highlight-bash', html)
                    self.assertNotIn("environnment", html)
                    self.assertNotIn("soley", html)


if __name__ == "__main__":
    unittest.main()
