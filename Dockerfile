FROM nvidia/cuda
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

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

ADD . /home/cli


#RUN bash /home/cli/graphistry/bootstrap/ubuntu/10-system-deps.sh
RUN bash /home/cli/graphistry/bootstrap/ubuntu/20-docker.sh
#RUN bash /home/cli/graphistry/bootstrap/ubuntu/30-CUDA.sh
#RUN bash /home/cli/graphistry/bootstrap/ubuntu/40-nvidia-docker.sh
RUN sudo pip3.6 install -r /home/cli/graphistry/requirements.txt

RUN cd /home/cli && sudo python3.6 setup.py install

WORKDIR /home
