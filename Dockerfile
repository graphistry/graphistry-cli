FROM nvidia/cuda
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Flag to let launch.sh know this is a container so it can insert
# the API url `curl -s http://localhost:3476/docker/cli`
ENV GCLI_CONTAINER True

# Trick launch.sh into thinking there's no GPU
# so we can just use the API to the host
ENV NV_GPU "-1"

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        wget \
        curl \
        git \
        keyboard-configuration \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        build-essential \
        libffi-dev

RUN add-apt-repository ppa:jonathonf/python-3.6 && apt-get update
RUN apt-get install -y --no-install-recommends \
        python3.6 \
        python3.6-dev && \
        rm -rf /var/lib/apt/lists/*

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3.6 get-pip.py

RUN mkdir -p /home/user
ADD . /home/user/graphistry-cli



RUN bash /home/user/graphistry-cli/graphistry/bootstrap/ubuntu/20-docker.sh
RUN sudo pip3.6 install -r /home/user/graphistry-cli/graphistry/requirements.txt

RUN cd /home/user/graphistry-cli && sudo python3.6 setup.py install

WORKDIR /home/user
