FROM ubuntu:16.04
RUN apt-get update && apt-get install -y sudo wget

ADD . /cli

RUN bash /cli/graphistry/bootstrap/ubuntu/10-system-deps.sh
RUN bash /cli/graphistry/bootstrap/ubuntu/20-docker.sh
RUN bash /cli/graphistry/bootstrap/ubuntu/30-CUDA.sh
RUN bash /cli/graphistry/bootstrap/ubuntu/40-nvidia-docker.sh
RUN sudo pip3 install -r /cli/graphistry/requirements.txt

RUN cd cli && sudo python3 setup.py install

WORKDIR /cli
