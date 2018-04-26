FROM ubuntu:17.10
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        wget \
        keyboard-configuration \
        vim-nox \
        dh-make \
        dh-systemd \
        fakeroot \
        build-essential \
        devscripts && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --non-unique --uid $USER_ID nvidia && chown nvidia: .

ADD . /cli


RUN bash /cli/graphistry/bootstrap/ubuntu/10-system-deps.sh
RUN bash /cli/graphistry/bootstrap/ubuntu/20-docker.sh
RUN bash /cli/graphistry/bootstrap/ubuntu/30-CUDA.sh
#RUN bash /cli/graphistry/bootstrap/ubuntu/40-nvidia-docker.sh
RUN sudo pip3 install -r /cli/graphistry/requirements.txt

RUN cd cli && sudo python3 setup.py install

WORKDIR /cli
