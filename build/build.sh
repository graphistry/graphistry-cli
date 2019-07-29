#!/bin/bash

### Generates ~/readme.pdf and ~/hardware-software.pdf
### ~/build $ ./build.sh

echo "==== BUILDING readme.pdf ===="
docker run --rm -it -v $PWD/..:/source jagregory/pandoc --toc -V documentclass=report -s \
	README.md \
	hardware-software.md \
	docs/aws.md \
	docs/aws_marketplace.md \
	docs/azure.md \
	docs/bridge.md \
	docs/browser.md \
	docs/configure-investigation.md \
	docs/configure.md \
	docs/debug-container-networking.md \
	docs/debug-faq.md \
	docs/debug-logs.md \
	docs/developer.md \
	docs/nvidia-docker-in-docker.md \
	docs/templates.md \
	docs/testing-an-install.md \
	docs/threatmodel.md \
	docs/update-backup-migrate.md \
	docs/user-creation.md \
	-o readme.pdf


echo "==== BUILDING hardware-software.pdf ===="
docker run --rm -it -v $PWD/..:/source jagregory/pandoc --toc -V documentclass=report -s \
	hardware-software.md \
	-o hardware-software.pdf

ls -al ../*.pdf