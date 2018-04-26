FROM nvidia/cuda
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        wget \
        curl \
        keyboard-configuration \
        software-properties-common

RUN add-apt-repository ppa:jonathonf/python-3.6 && apt-get update
RUN apt-get install -y --no-install-recommends \
        python3.6 \
        python3.6-dev && \
        rm -rf /var/lib/apt/lists/*

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3.6 get-pip.py

ADD . /cli


RUN bash /cli/graphistry/bootstrap/ubuntu/10-system-deps.sh
RUN bash /cli/graphistry/bootstrap/ubuntu/20-docker.sh
#RUN bash /cli/graphistry/bootstrap/ubuntu/30-CUDA.sh
#RUN bash /cli/graphistry/bootstrap/ubuntu/40-nvidia-docker.sh
RUN sudo pip3 install -r /cli/graphistry/requirements.txt

RUN cd cli && sudo python3 setup.py install

WORKDIR /cli
