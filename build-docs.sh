#!/bin/bash
# Build Graphistry CLI documentation using Docker

set -e

COMPOSE_FILE="infra/docker-compose.yml"

show_help() {
    cat << EOF
Build Graphistry CLI documentation using Docker

Usage: ./build-docs.sh [FORMAT]

Formats:
  html    Build HTML documentation (default)
  epub    Build EPUB documentation
  pdf     Build PDF documentation
  all     Build all formats (HTML, EPUB, PDF)

Options:
  -h, --help    Show this help message

Examples:
  ./build-docs.sh           # Build HTML only
  ./build-docs.sh html      # Build HTML only
  ./build-docs.sh pdf       # Build PDF only
  ./build-docs.sh all       # Build all formats

Output Locations:
  HTML: _build/html/index.html
  EPUB: _build/epub/
  PDF:  _build/latexpdf/Graphistry.pdf
EOF
}

# Handle help flag
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
esac

DOCS_FORMAT="${1:-html}"

# Validate format
case "$DOCS_FORMAT" in
    html|epub|pdf|all)
        ;;
    *)
        echo "Error: Invalid format '$DOCS_FORMAT'"
        echo "Run './build-docs.sh --help' for usage"
        exit 1
        ;;
esac

# Check we're in the right directory
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: $COMPOSE_FILE not found"
    echo "Make sure you are in the graphistry-cli root directory"
    echo "Current directory: $PWD"
    exit 1
fi

# Check Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: docker command not found"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running"
    echo "Please start Docker and try again"
    exit 1
fi

echo "====================================="
echo "Building Graphistry CLI Documentation"
echo "====================================="
echo "Format: $DOCS_FORMAT"
echo ""

# Build docs using docker compose
BUILD_EXIT_CODE=0
DOCS_FORMAT="$DOCS_FORMAT" docker compose -f "$COMPOSE_FILE" up --build || BUILD_EXIT_CODE=$?

# Always clean up containers/networks
echo ""
echo "Cleaning up Docker resources..."
docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

# Check if build succeeded
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "====================================="
    echo "Build FAILED (exit code: $BUILD_EXIT_CODE)"
    echo "====================================="
    echo "Check the output above for errors"
    exit $BUILD_EXIT_CODE
fi

echo ""
echo "====================================="
echo "Build Complete!"
echo "====================================="
echo ""
echo "Output Locations:"
case "$DOCS_FORMAT" in
    html)
        echo "  HTML: _build/html/index.html"
        ;;
    epub)
        echo "  EPUB: _build/epub/"
        ;;
    pdf)
        echo "  PDF:  _build/latexpdf/Graphistry.pdf"
        ;;
    all)
        echo "  HTML: _build/html/index.html"
        echo "  EPUB: _build/epub/"
        echo "  PDF:  _build/latexpdf/Graphistry.pdf"
        ;;
esac
echo ""
echo "View the docs:"
echo "  xdg-open _build/html/index.html"
echo ""
