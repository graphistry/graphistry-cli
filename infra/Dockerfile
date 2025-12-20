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

# Convert absolute readthedocs URLs to relative paths for air-gapped environments
# Convert markdown links to raw HTML links so myst passes them through as-is
RUN sed -i '\
    s|\[Top commands\](https://graphistry-admin-docs.readthedocs.io/en/latest/commands.html)|<a href="commands.html">Top commands</a>|g; \
    s|\[Plan deployments\](https://graphistry-admin-docs.readthedocs.io/en/latest/planning/hardware-software.html)|<a href="planning/hardware-software.html">Plan deployments</a>|g; \
    s|\[Cloud\](https://graphistry-admin-docs.readthedocs.io/en/latest/install/cloud/index.html)|<a href="install/cloud/index.html">Cloud</a>|g; \
    s|\[On-prem\](https://graphistry-admin-docs.readthedocs.io/en/latest/install/on-prem/index.html)|<a href="install/on-prem/index.html">On-prem</a>|g; \
    s|\[Configure\](https://graphistry-admin-docs.readthedocs.io/en/latest/app-config/index.html)|<a href="app-config/index.html">Configure</a>|g; \
    s|\[Debugging \& performance\](https://graphistry-admin-docs.readthedocs.io/en/latest/debugging/index.html)|<a href="debugging/index.html">Debugging \& performance</a>|g; \
    s|\[Security\](https://graphistry-admin-docs.readthedocs.io/en/latest/security/index.html)|<a href="security/index.html">Security</a>|g; \
    s|\[Operations \& tools\](https://graphistry-admin-docs.readthedocs.io/en/latest/tools/index.html)|<a href="tools/index.html">Operations \& tools</a>|g; \
    s|\[FAQ\](https://graphistry-admin-docs.readthedocs.io/en/latest/faq/index.html)|<a href="faq.html">FAQ</a>|g; \
    s|\[support options\](https://graphistry-admin-docs.readthedocs.io/en/latest/support.html)|<a href="support.html">support options</a>|g' \
    /docs/source/README.md

WORKDIR /docs/source

CMD ["/build-docs.sh"]
