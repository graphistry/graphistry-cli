### Generates docs/readme.pdf and docs/hardware-software.pdf

docker run --rm -it -v $PWD/..:/source jagregory/pandoc --toc -V documentclass=report -s \
	README.md \
	docs/configure.md \
	docs/hardware-software.md \
	docs/aws.md \
	docs/azure.md \
	docs/debug-faq.md \
	docs/debug-logs.md \
	docs/debug-container-networking.md \
	-o docs/readme.pdf


docker run --rm -it -v $PWD/..:/source jagregory/pandoc --toc -V documentclass=report -s docs/hardware-software.md -o docs/hardware-software.pdf

cp *.pdf ../dist/dist/docs/

ls -al *.pdf
ls -al ../dist/dist/docs/*.pdf