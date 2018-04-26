
docker build -t gcli .
# https://forums.docker.com/t/how-can-i-run-docker-command-inside-a-docker-container/337

# Run the CLI container with --net=host to access host networking and mount the docker.sock
nvidia-docker run --net=host -it -v /var/run/docker.sock:/var/run/docker.sock gcli bash

# https://github.com/NVIDIA/nvidia-docker/issues/380
# curl the docker cli REST api before you name the image and somehow docker will launch nvidia docker containers just fine
docker run -ti --rm `curl -s http://localhost:3476/docker/cli` nvidia/cuda nvidia-smi



# https://stackoverflow.com/questions/22944631/how-to-get-the-ip-address-of-the-docker-host-from-inside-a-docker-container
export HOST_MACHINE_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
docker run -ti --rm `curl -s http://$HOST_MACHINE_ADDRESS:3476/docker/cli` nvidia/cuda nvidia-smi