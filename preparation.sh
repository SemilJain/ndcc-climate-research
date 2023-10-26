#!/bin/bash

# Change permissions for the script
sudo chmod 755 setup-grow-rootfs.sh

# Set the RESIZEROOT environment variable and run the script
sudo RESIZEROOT=0 ./setup-grow-rootfs.sh

# Install docker
if ! command -v docker; then
  # If Docker is not installed, install it
  sh get-docker.sh
fi

# Allow non-root docker access
if ! getent group docker; then
  # If the group doesn't exist, create it
  sudo groupadd docker
fi

if ! groups | grep "docker"; then
  # If the user is not a member, add them to the group
  sudo usermod -aG docker $USER
  newgrp docker
fi

# Install Docker compose
sudo apt install docker-compose -y

sudo apt -y install libxml2-utils


# Create Repos
export PROJ_DIR=`pwd`
export PROJ_VERSION="4.1.0"
DATASET=$(geni-get manifest | xmllint --xpath "string(//*[local-name()='data_item'])" -)
export CASE_DIR=${PROJ_DIR}/${DATASET}
mkdir -p ${CASE_DIR}

# Get github repo
if ! ls | grep "container-dtc-nwp"; then
curl -SL https://github.com/NCAR/container-dtc-nwp/archive/refs/tags/v${PROJ_VERSION}.tar.gz | tar zxC . && mv container-dtc-nwp-${PROJ_VERSION} container-dtc-nwp
fi

# Get all dockers from HUB
cd ${PROJ_DIR}
docker pull dtcenter/wps_wrf:${PROJ_VERSION}
docker pull dtcenter/gsi:${PROJ_VERSION}
docker pull dtcenter/upp:${PROJ_VERSION}
docker pull dtcenter/python:${PROJ_VERSION}
docker pull dtcenter/nwp-container-met:${PROJ_VERSION}
docker pull dtcenter/nwp-container-metviewer:${PROJ_VERSION}

if [ "$(docker images | wc -l)" -ne 7 ]; then
  echo "Error: The number of Docker images is not 7."
  exit 1  # Exit with an error code
fi

cd ${CASE_DIR}
mkdir -p wpsprd wrfprd gsiprd postprd pythonprd metprd metviewer/mysql
cd ${PROJ_DIR}
echo "Preparation done. The script completed successfully."
