#!/bin/bash

### Generates ~/readme.pdf and ~/hardware-software.pdf
### ~/build $ ./build.sh

echo "==== BUILDING readme.pdf ===="
DOCS=$(ls docs/*.md)
docker run --rm -it -v $PWD/..:/source jagregory/pandoc --toc -V documentclass=report -s \
	README.md \
	$DOCS \
	-o readme.pdf

echo "==== BUILDING hardware-software.pdf ===="
docker run --rm -it -v $PWD/..:/source jagregory/pandoc --toc -V documentclass=report -s \
	docs/hardware-software.md \
	-o hardware-software.pdf

ls -al ../*.pdf
