#!/bin/sh
set -ex

build_html() {
    sphinx-build -vv -b html -d /docs/doctrees . /docs/_build/html
}

build_epub() {
    sphinx-build -b epub -d /docs/doctrees . /docs/_build/epub
}

build_pdf() {
    sphinx-build -b latex -d /docs/doctrees . /docs/_build/latexpdf
    cd /docs/_build/latexpdf
    # Run pdflatex twice to resolve cross-references, using batchmode for non-interactive build
    pdflatex -file-line-error -interaction=nonstopmode Graphistry.tex || test -f /docs/_build/latexpdf/Graphistry.pdf
    pdflatex -file-line-error -interaction=nonstopmode Graphistry.tex || test -f /docs/_build/latexpdf/Graphistry.pdf
}

echo "Building documentation: DOCS_FORMAT=${DOCS_FORMAT}"
echo "PWD: $(pwd)"
echo "Contents of /docs: $(ls /docs)"
echo "Contents of /docs/source (head): $(ls /docs/source | head -n 10)"

case "$DOCS_FORMAT" in
    html)
        build_html
        ;;
    epub)
        build_epub
        ;;
    pdf)
        build_pdf
        ;;
    all)
        build_html
        build_epub
        build_pdf
        ;;
    *)
        echo "Invalid DOCS_FORMAT value: $DOCS_FORMAT"
        exit 1
        ;;
esac