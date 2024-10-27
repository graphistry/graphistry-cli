FROM sphinxdoc/sphinx:8.0.2

WORKDIR /docs

COPY infra/requirements-system.txt /requirements-system.txt
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update \
    && apt-get install -y $(cat /requirements-system.txt) \
    && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install graphistry[docs]

COPY infra/requirements-python.txt /requirements-python.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install -r /requirements-python.txt

COPY docs /graphistry-cli

COPY infra/build-docs.sh /build-docs.sh
COPY docs/ /docs/source
COPY README.md /docs/source/README.md

WORKDIR /docs/source

CMD ["/build-docs.sh"]
