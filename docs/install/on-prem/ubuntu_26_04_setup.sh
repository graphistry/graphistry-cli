#!/bin/bash
set -exo pipefail

##############################################################################
#   This script is provided as sample reference only, for installing         #
#     pre-requisites for Graphistry Enterprise Server on an "Ubuntu 26.04    #
#     LTS" (resolute) base image, on-prem or in the cloud. The process       #
#     follows loosely the steps taken when we build the underlying base      #
#     images.                                                                #
#                                                                            #
#   The script will reboot the machine once, and will need to be run         #
#    a second time to finish the installation. It uses a breadcrumb          #
#    file to know whether the first portion has been run or not.             #
#                                                                            #
#    To run the script again from the beginning, delete the                  #
#    file: ~/g-part1.lck                                                     #
#                                                                            #
#   Assumptions:                                                             #
#   1. the user running this script is the ubuntu user                       #
#      (override with GRAPHISTRY_USER)                                       #
#   2. user has sudo rights                                                  #
#   3. graphistry software is unpacked into `/home/ubuntu/graphistry`        #
#      (override with GRAPHISTRY_HOME)                                       #
#                                                                            #
#   Settings can be passed as environment variables, or placed in a `.env`   #
#    file next to this script. See `ubuntu_26_04_setup.example.env`.         #
#                                                                            #
#   Nvidia driver, two sources (SECURE_BOOT in `.env`):                      #
#   - SECURE_BOOT=0 (default): Nvidia's CUDA apt repo, exact version pinned  #
#     (595.91.07) with nvidia-driver-pinning-<version>; kernel module built  #
#     locally by DKMS, unsigned, so it needs Secure Boot off (or a MOK key   #
#     enrolled at the console). The version never moves, including across    #
#     kernel updates.                                                        #
#   - SECURE_BOOT=1: Ubuntu's <branch>-server driver (595-server) with       #
#     prebuilt kernel modules signed by Canonical, so it loads with Secure   #
#     Boot on and needs no compiler. Ubuntu ships point releases within the  #
#     branch with kernel updates, so the version can move (595.91.07 today). #
#                                                                            #
#   SECURITY UPDATES ARE TURNED OFF: stage 1 removes unattended-upgrades and #
#    disables the apt-daily timers and APT::Periodic, so the host installs   #
#    no patches on its own. This avoids unplanned driver, kernel or Docker   #
#    changes and reboots under a running GPU server. Patch on your own       #
#    schedule in a maintenance window:                                       #
#        sudo apt-get update && sudo apt-get dist-upgrade && sudo reboot     #
#                                                                            #
#   Changes vs ubuntu_22_04_setup.sh:                                        #
#   - Nvidia driver 595 instead of 470 (see above); open kernel modules by   #
#     default (Turing / T4 and newer), proprietary for Pascal / Volta        #
#   - nvidia-container-toolkit from the current libnvidia-container repo     #
#     (the old nvidia-docker repo has no ubuntu26.04 list) and configured    #
#     via `nvidia-ctk`; apt-key replaced with signed-by keyrings             #
#   - Docker from Docker's apt repo instead of `curl get.docker.com | sh`    #
#   - python3.8 / python2.7 removed (not available on resolute)              #
#   - DNS fallback via systemd-resolved drop-in instead of appending to the  #
#     /etc/resolv.conf stub, which is regenerated on every boot              #
#   - needrestart prompts suppressed, apt lock waits, sudo env fixes         #
#   - any apt failure stops the script, including repo fetch errors          #
#   - optional Docker log size limit (DOCKER_LOG_MAX_SIZE)                   #
#                                                                            #
#    for assistance:  support@graphistry.com                                 #
#                                                                            #
##############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/.env"
    set +a
fi

GRAPHISTRY_USER=${GRAPHISTRY_USER:-ubuntu}
GRAPHISTRY_HOME=${GRAPHISTRY_HOME:-/home/${GRAPHISTRY_USER}/graphistry}
SECURE_BOOT=${SECURE_BOOT:-0}
NVIDIA_DRIVER_VERSION=${NVIDIA_DRIVER_VERSION:-595.91.07}
NVIDIA_UBUNTU_BRANCH=${NVIDIA_UBUNTU_BRANCH:-${NVIDIA_DRIVER_VERSION%%.*}-server}
NVIDIA_KERNEL_MODULES=${NVIDIA_KERNEL_MODULES:-open}
NVIDIA_REPO=${NVIDIA_REPO:-https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2604/x86_64}
ALLOW_SECURE_BOOT_MOK=${ALLOW_SECURE_BOOT_MOK:-0}
NVIDIA_CONTAINER=${NVIDIA_CONTAINER:-nvidia/cuda:12.8.1-base-ubuntu24.04}
DOCKER_VERSION=${DOCKER_VERSION:-}
DOCKER_CONTAINERD_SNAPSHOTTER=${DOCKER_CONTAINERD_SNAPSHOTTER:-false}
DOCKER_LOG_MAX_SIZE=${DOCKER_LOG_MAX_SIZE:-}
DOCKER_LOG_MAX_FILE=${DOCKER_LOG_MAX_FILE:-3}
REQUIRE_GPU=${REQUIRE_GPU:-1}
DISABLE_SNAPD=${DISABLE_SNAPD:-1}
FALLBACK_DNS=${FALLBACK_DNS:-8.8.8.8 8.8.4.4}
AUTO_REBOOT=${AUTO_REBOOT:-1}
REBOOT_DELAY=${REBOOT_DELAY:-30}

lock_file=${LOCK_FILE:-~/g-part1.lck}

# sudo resets the environment, so DEBIAN_FRONTEND must be set after sudo.
# needrestart (default since 24.04) otherwise prompts during apt and hangs scripts.
# Update::Error-Mode=any: `apt-get update` otherwise exits 0 when a repo fails to fetch.
apt_get() {
    sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a NEEDRESTART_SUSPEND=1 \
        apt-get -y \
        -o APT::Update::Error-Mode=any \
        -o DPkg::Lock::Timeout=600 \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        "$@"
}

# 100-verify.sh:

. /etc/os-release
if [ "${VERSION_ID}" != "26.04" ]; then
    echo "ERROR: this script targets Ubuntu 26.04, found ${PRETTY_NAME}" >&2
    exit 1
fi

case "${NVIDIA_KERNEL_MODULES}" in
    open) nvidia_headless_pkg=nvidia-headless-open; ubuntu_open_suffix=-open ;;
    proprietary) nvidia_headless_pkg=nvidia-headless; ubuntu_open_suffix= ;;
    *) echo "ERROR: NVIDIA_KERNEL_MODULES must be open or proprietary" >&2; exit 1 ;;
esac
case "${SECURE_BOOT}" in
    0|1) ;;
    *) echo "ERROR: SECURE_BOOT must be 0 (Nvidia repo, exact pin, DKMS) or 1 (Ubuntu signed modules)" >&2; exit 1 ;;
esac
# SECURE_BOOT=1 packages, e.g. nvidia-headless-no-dkms-595-server-open
ubuntu_driver_pkg=nvidia-headless-no-dkms-${NVIDIA_UBUNTU_BRANCH}${ubuntu_open_suffix}

# installed_pkgs pkg...: print the given packages that are installed
installed_pkgs() {
    dpkg-query -W -f='${Package} ${Status}\n' "$@" 2>/dev/null | awk '/ ok installed$/ {print $1}' || true
}

if [ ! -f ${lock_file} ]; then

    # 200-reset.sh

    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--            ubuntu_disable_init.sh         --"
    echo "--                                           --"
    echo "-----------------------------------------------"

    echo "----- CHECK APT -------"
    ps -aux | grep apt || echo ok

    # NOTE: this turns off automatic security updates (see the header). The host gets
    # no patches until an admin runs apt-get dist-upgrade. To turn them back on later:
    #   sudo apt-get install unattended-upgrades
    #   sudo rm /etc/apt/apt.conf.d/99periodic-disable
    #   sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
    # With SECURE_BOOT=1 that can also update the Nvidia driver (it ships in the
    # -security pocket), leaving the loaded module out of step with userspace until
    # the next reboot.
    echo "---- DISABLE apt-daily ----"
    ### https://stackoverflow.com/questions/45269225/ansible-playbook-fails-to-lock-apt/51919678#51919678
    sudo systemctl disable --now 'apt-daily.timer'
    sudo systemctl disable --now 'apt-daily-upgrade.timer'
    sudo systemctl daemon-reload

    # Wait for any in-flight apt-daily runs, then remove unattended-upgrades
    sudo systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true
    apt_get purge unattended-upgrades

    echo "---- DISABLE apt periodic ----"
    #https://askubuntu.com/questions/1006189/how-to-stop-apt-from-doing-anything
    echo 'APT::Periodic::Enable "0";' | \
    sudo tee /etc/apt/apt.conf.d/99periodic-disable

    if [ "${DISABLE_SNAPD}" = "1" ]; then
        # snapd.socket re-activates snapd on demand, so stop both
        sudo systemctl disable --now snapd.socket snapd.service || echo 'failed to disable snapd'
    fi

    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--        done ubuntu_disable_init.sh        --"
    echo "--                                           --"
    echo "-----------------------------------------------"


    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--            fix_hosts.sh                   --"
    echo "--                                           --"
    echo "-----------------------------------------------"

    # Newer iproute2 appends "uid N" to the output, so pick the field after "src"
    ip=$(ip route get 1 | awk '{for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit }}')
    hostname=$(hostname)
    sudo cp -n /etc/hosts /etc/hosts.pre-graphistry
    sudo tee /etc/hosts > /dev/null << EOF
127.0.0.1 localhost
${ip} ${hostname}
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF
    # Keep cloud-init from rewriting /etc/hosts on the next boot
    if [ -d /etc/cloud/cloud.cfg.d ]; then
        echo 'manage_etc_hosts: false' | sudo tee /etc/cloud/cloud.cfg.d/99-graphistry-hosts.cfg
    fi

    echo "----- old dns -----------"
    resolvectl status || cat /etc/resolv.conf

    # /etc/resolv.conf is a systemd-resolved stub on 26.04: edits are lost on reboot.
    # FallbackDNS is only used when no other DNS server is known, so site DNS still wins.
    if [ -n "${FALLBACK_DNS}" ]; then
        echo "----- add fallback dns ----"
        sudo mkdir -p /etc/systemd/resolved.conf.d
        printf '[Resolve]\nFallbackDNS=%s\n' "${FALLBACK_DNS}" | \
            sudo tee /etc/systemd/resolved.conf.d/99-graphistry-fallback-dns.conf
        sudo systemctl restart systemd-resolved
    fi

    echo "-----------------------------------------------"
    echo "--                                           --"
    echo "--        done fix_hosts.sh                  --"
    echo "--                                           --"
    echo "-----------------------------------------------"


    # 300-populate.sh:

    cat << EOF > ~/tmp_00-header
#!/bin/sh
#
#    00-header - create the header of the MOTD
#    Copyright (C) 2009-2010 Canonical Ltd.
#
#    Authors: Dustin Kirkland <kirkland@canonical.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

[ -r /etc/lsb-release ] && . /etc/lsb-release

if [ -z "\$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
        # Fall back to using the very slow lsb_release utility
        DISTRIB_DESCRIPTION=\$(lsb_release -s -d)
fi


printf "=============================================================================\n"
printf "                                                                             \n"
printf " ______  ______ _______  _____  _     _ _____ _______ _______  ______ __   __\n"
printf "|  ____ |_____/ |_____| |_____] |_____|   |   |______    |    |_____/   \_/  \n"
printf "|_____| |    \_ |     | |       |     | __|__ ______|    |    |    \_    |   \n"
printf "                                                                             \n"
printf "                                                                             \n"
printf "=============================================================================\n"
printf "\n"
printf " * Graphistry: ${GRAPHISTRY_HOME}\n"
printf " * Main docs: http://localhost/docs and hub.graphistry.com/docs\n"
printf " * Admin docs: ${GRAPHISTRY_HOME}/docs and https://github.com/graphistry/graphistry-cli\n"
printf " * Support: https://graphistry.zendesk.com\n"
printf " * Private dedicated Slack channel: Contact your support staff\n"
printf "\n"
printf "=============================================================================\n"
EOF

    sudo mv ~/tmp_00-header /etc/update-motd.d/00-header
    sudo chmod 755 /etc/update-motd.d/00-header


    # 400-upgrade.sh:

    # Any apt failure stops the script (set -e): continuing on a half-upgraded
    # system just fails later in a less obvious place.
    apt_get update
    # dist-upgrade, not upgrade: plain upgrade keeps back the kernel meta packages
    apt_get dist-upgrade
    apt_get install build-essential ca-certificates


    # 510-base-util.sh:

    apt_get install \
        ca-certificates \
        curl \
        gnupg \
        htop \
        iftop \
        jq \
        lsb-release \
        mokutil \
        parallel \
        pciutils \
        tree \
        unzip \
        zip

    # 520-base-python.sh:

    # Graphistry runs its Python inside containers; resolute ships python3.14 and
    # has no python3.8 / python2.7 packages, so only provide the system python3.
    apt_get install python3 python3-pip python3-venv
    python3 --version

    # 530-nvidia-driver.sh:

    if lspci | grep -i nvidia; then
        echo "Found Nvidia GPU"
    elif [ "${REQUIRE_GPU}" = "1" ]; then
        echo "ERROR: no Nvidia GPU found by lspci (set REQUIRE_GPU=0 to install anyway)" >&2
        exit 1
    else
        echo "WARNING: no Nvidia GPU found, installing driver packages anyway (REQUIRE_GPU=0)"
    fi

    secure_boot_on=0
    if mokutil --sb-state 2>/dev/null | grep 'SecureBoot enabled' > /dev/null; then
        secure_boot_on=1
    fi
    echo "Secure Boot enabled: ${secure_boot_on}, SECURE_BOOT=${SECURE_BOOT}"

    # The two driver sources conflict; switching on an installed host is not supported
    if [ "${SECURE_BOOT}" = "1" ]; then
        other_source=$(installed_pkgs 'nvidia-driver-pinning-*' libnvidia-compute)
    else
        other_source=$(installed_pkgs 'nvidia-headless-no-dkms-[0-9]*')
    fi
    if [ -n "${other_source}" ]; then
        echo "ERROR: the other Nvidia driver source is already installed (${other_source//$'\n'/ })." >&2
        echo "       Use the same SECURE_BOOT value as the first install, or purge the driver first." >&2
        exit 1
    fi

    # Kernel flavour picks the matching headers (SECURE_BOOT=0) or signed modules (=1)
    kernel_flavour=generic
    for f in generic-hwe-26.04 aws azure gcp oracle generic virtual; do
        if [ -n "$(installed_pkgs "linux-image-${f}")" ]; then
            kernel_flavour=${f}
            break
        fi
    done
    # linux-image-virtual runs the generic kernel
    [ "${kernel_flavour}" = virtual ] && kernel_flavour=generic
    echo "Kernel flavour: ${kernel_flavour}"

    # Driver goes in after the upgrade so its kernel module is in place for the
    # kernel the machine reboots into.
    if [ "${SECURE_BOOT}" = "1" ]; then

        # Ubuntu's driver with prebuilt kernel modules signed by Canonical: loads with
        # Secure Boot on, no DKMS. The linux-modules meta package follows kernel updates.
        ubuntu_modules_pkg=linux-modules-nvidia-${NVIDIA_UBUNTU_BRANCH}${ubuntu_open_suffix}-${kernel_flavour}
        if [ -n "$(installed_pkgs "${ubuntu_driver_pkg}")" ]; then
            echo "Nvidia driver ${ubuntu_driver_pkg} already installed"
        else
            for p in "${ubuntu_modules_pkg}" "${ubuntu_driver_pkg}"; do
                if ! apt-cache show "${p}" > /dev/null 2>&1; then
                    echo "ERROR: ${p} is not in the Ubuntu archive (kernel flavour ${kernel_flavour}," >&2
                    echo "       branch ${NVIDIA_UBUNTU_BRANCH}). Use SECURE_BOOT=0, or set NVIDIA_UBUNTU_BRANCH." >&2
                    exit 1
                fi
            done
            apt_get install "${ubuntu_modules_pkg}" "${ubuntu_driver_pkg}" "nvidia-utils-${NVIDIA_UBUNTU_BRANCH}"
        fi

        ubuntu_driver_version=$(dpkg-query -W -f='${Version}' "nvidia-utils-${NVIDIA_UBUNTU_BRANCH}")
        ubuntu_driver_version=${ubuntu_driver_version%%-*}
        # Fail now rather than after the reboot if the newest kernel has no matching module
        newest_kernel=$(find /boot -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' | sed 's/^vmlinuz-//' | sort -V | tail -1)
        module_version=$(modinfo -k "${newest_kernel}" -F version nvidia)
        if [ "${module_version}" != "${ubuntu_driver_version}" ]; then
            echo "ERROR: kernel ${newest_kernel} has nvidia module ${module_version}, driver is ${ubuntu_driver_version}" >&2
            exit 1
        fi
        if [ "${ubuntu_driver_version}" != "${NVIDIA_DRIVER_VERSION}" ]; then
            echo "WARNING: Ubuntu's ${NVIDIA_UBUNTU_BRANCH} driver is ${ubuntu_driver_version}, not ${NVIDIA_DRIVER_VERSION}."
            echo "         Use SECURE_BOOT=0 if the exact version is required."
        fi

    else

        # Nvidia's repo modules are built locally by DKMS and are not signed by Canonical.
        # With Secure Boot on they will not load until a MOK key is enrolled at the console.
        if [ "${secure_boot_on}" = "1" ]; then
            if [ "${ALLOW_SECURE_BOOT_MOK}" = "1" ]; then
                echo "WARNING: Secure Boot is enabled; enroll the DKMS MOK key at the console on reboot"
            else
                echo "ERROR: Secure Boot is enabled and SECURE_BOOT=0 builds unsigned DKMS modules." >&2
                echo "       Set SECURE_BOOT=1 for Ubuntu's signed driver, disable Secure Boot, or set" >&2
                echo "       ALLOW_SECURE_BOOT_MOK=1 if you can enroll the MOK key at the console." >&2
                exit 1
            fi
        fi

        # The pinning package locks every driver package to one version
        installed_driver=$(dpkg-query -W -f='${Version}' libnvidia-compute 2>/dev/null || true)
        if [[ "${installed_driver}" == "${NVIDIA_DRIVER_VERSION}"-* ]]; then
            echo "Nvidia driver ${NVIDIA_DRIVER_VERSION} already installed"
        else
            # Headers meta package keeps DKMS building for future kernel updates too
            apt_get install dkms "linux-headers-${kernel_flavour}"

            if [ -z "$(installed_pkgs cuda-keyring)" ]; then
                curl -fsSL -o ~/tmp_cuda-keyring.deb "${NVIDIA_REPO}/cuda-keyring_1.1-1_all.deb"
                sudo dpkg -i ~/tmp_cuda-keyring.deb
                rm -f ~/tmp_cuda-keyring.deb
            fi
            apt_get update
            apt_get install "nvidia-driver-pinning-${NVIDIA_DRIVER_VERSION}"
            apt_get install "${nvidia_headless_pkg}" nvidia-persistenced

            # Fail now rather than after the reboot if DKMS did not build the module
            dkms status | grep "${NVIDIA_DRIVER_VERSION}.*installed" > /dev/null
        fi

    fi

    # Applied on next boot, before docker loads the overlay module
    echo 'options overlay metacopy=off redirect_dir=off' | \
        sudo tee /etc/modprobe.d/disable_overlay_redirect_dir.conf

    touch ${lock_file}

    if [ "${AUTO_REBOOT}" = "1" ]; then
        echo
        echo "WARNING: rebooting in ${REBOOT_DELAY} seconds, hit CTRL-C to cancel"
        echo "         after reboot, run this script again to finish the install"
        echo
        sleep "${REBOOT_DELAY}"
        sudo reboot
    else
        echo "Stage 1 done. Reboot, then run this script again to finish the install."
    fi
    exit 0

fi

echo "starting stage 2 graphistry pre-reqs..."; echo

if [ "${REQUIRE_GPU}" = "1" ]; then
    nvidia-smi
    loaded_driver=$(nvidia-smi -i 0 --query-gpu=driver_version --format=csv,noheader)
else
    # No GPU: check the module DKMS built for the running kernel instead
    loaded_driver=$(modinfo -F version nvidia)
fi
if [ "${SECURE_BOOT}" = "1" ]; then
    # Ubuntu sets the point release within the branch; only the branch must match
    if [ "${loaded_driver%%.*}" != "${NVIDIA_UBUNTU_BRANCH%%-*}" ]; then
        echo "ERROR: expected Nvidia driver branch ${NVIDIA_UBUNTU_BRANCH}, found ${loaded_driver}" >&2
        exit 1
    fi
    if [ "${loaded_driver}" != "${NVIDIA_DRIVER_VERSION}" ]; then
        echo "WARNING: Nvidia driver ${loaded_driver} loaded, not ${NVIDIA_DRIVER_VERSION} (SECURE_BOOT=1 follows Ubuntu's branch)"
    fi
elif [ "${loaded_driver}" != "${NVIDIA_DRIVER_VERSION}" ]; then
    echo "ERROR: expected Nvidia driver ${NVIDIA_DRIVER_VERSION}, found ${loaded_driver}" >&2
    exit 1
fi

# 532-docker.sh:

# Set daemon options before docker first starts: changing the image store later
# hides previously loaded images.
sudo mkdir -p /etc/docker
# DOCKER_LOG_MAX_SIZE caps each container's json-file log (applies to containers
# created after the change; existing ones keep their settings until recreated).
daemon_json=$( { sudo cat /etc/docker/daemon.json 2>/dev/null || echo '{}' ; } \
    | jq --argjson snap "${DOCKER_CONTAINERD_SNAPSHOTTER}" \
        --arg log_size "${DOCKER_LOG_MAX_SIZE}" --arg log_files "${DOCKER_LOG_MAX_FILE}" \
        '. + {"live-restore": true}
        | .features = ((.features // {}) + {"containerd-snapshotter": $snap})
        | if $log_size != "" then
            ."log-driver" = "json-file"
            | ."log-opts" = ((."log-opts" // {}) + {"max-size": $log_size, "max-file": $log_files})
          else . end' )
echo "${daemon_json}" | sudo tee /etc/docker/daemon.json

sudo docker --version \
|| {
    # Only remove what is installed, so a real apt failure still stops the script
    old_docker=$(installed_pkgs docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)
    if [ -n "${old_docker}" ]; then
        # shellcheck disable=SC2086
        apt_get remove ${old_docker}
    fi

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list
    apt_get update

    echo "Available: " && apt-cache madison docker-ce

    if [ -n "${DOCKER_VERSION}" ]; then
        apt_get install "docker-ce=${DOCKER_VERSION}" "docker-ce-cli=${DOCKER_VERSION}" \
            containerd.io docker-buildx-plugin docker-compose-plugin
    else
        apt_get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
}

sudo systemctl enable --now docker
sudo usermod -aG docker "${GRAPHISTRY_USER}"

sudo docker --version
sudo docker info
sudo docker run --rm hello-world
if [ "$(sudo docker info --format '{{.Driver}}')" = "overlay2" ]; then
    sudo docker info | grep "Native Overlay Diff" | grep "true" || echo "WARNING: Native Overlay Diff is not true"
fi
sudo docker compose version

# 534-nvidia-docker.sh:

nvidia-ctk --version \
|| {
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt_get update
    apt_get install nvidia-container-toolkit
}

# set nvidia as default runtime (needed for docker compose); merges into daemon.json
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo systemctl restart docker
sudo cat /etc/docker/daemon.json

if [ "$(sudo docker info --format '{{.DefaultRuntime}}')" != "nvidia" ]; then
    echo "ERROR: docker default runtime is not nvidia" >&2
    exit 1
fi

if [ "${REQUIRE_GPU}" = "1" ]; then
    sudo docker run --rm --gpus all ${NVIDIA_CONTAINER} nvidia-smi
    sudo docker run --rm ${NVIDIA_CONTAINER} nvidia-smi
else
    echo "REQUIRE_GPU=0: skipping GPU container checks, testing the nvidia runtime without a GPU"
    sudo docker run --rm hello-world
fi


# graphistry-compose.service (after docker exists, so BindsTo resolves)

if [ -x "${GRAPHISTRY_HOME}/graphistry" ]; then
    compose_cmd="./graphistry"
else
    compose_cmd="docker compose"
fi

cat << EOF > ~/tmp_graphistry-compose.service
[Unit]
Description=make graphistry creds once, then run via docker compose
After=docker.service sockets.target network-online.target
Wants=network-online.target
BindsTo=docker.service sockets.target
ReloadPropagatedFrom=docker.service
ConditionPathIsDirectory=${GRAPHISTRY_HOME}

[Service]
Type=exec
User=${GRAPHISTRY_USER}
WorkingDirectory=${GRAPHISTRY_HOME}
Environment=COMPOSE_HTTP_TIMEOUT=180
ExecStart=/bin/sh -c '( grep -q SECRET_KEY ./data/config/custom.env || ./etc/scripts/cred-gen.sh >> ./data/config/custom.env; ) && exec ${compose_cmd} up'
ExecStop=/bin/sh -c '${compose_cmd} down'
Restart=on-failure
RestartSec=20

[Install]
WantedBy=multi-user.target
EOF

sudo mv ~/tmp_graphistry-compose.service /etc/systemd/system/graphistry-compose.service
sudo systemctl daemon-reload
sudo systemctl enable graphistry-compose.service

echo "Successfully installed all!"
echo "Next: cd ${GRAPHISTRY_HOME} && docker load -i containers.tar.gz && sudo systemctl start graphistry-compose"
