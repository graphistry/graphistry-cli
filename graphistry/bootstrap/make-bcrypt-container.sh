#!/bin/bash

cat >./NodeJSDockerfile <<EOL
FROM node:9-alpine

RUN npm install bcrypt-cli -g
EOL

docker build -t bcrypt -f NodeJSDockerfile .

rm NodeJSDockerfile

echo -e "\nTest bcrypt-cli Container\n"
echo "docker run -it bcrypt bcrypt-cli "xxxx" 10"
docker run -it bcrypt bcrypt-cli "xxxx" 10

