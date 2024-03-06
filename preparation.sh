#!/bin/bash

cd /users/$USER
# Define the log file path
LOG_FILE="/users/$USER/script_log.txt"

# Function to log a message
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

exec > >(tee -a "$LOG_FILE") 2>&1

log "Starting script..."

# Change permissions for the script
sudo chmod 755 ./setup-grow-rootfs.sh

# Set the RESIZEROOT environment variable and run the script
sudo RESIZEROOT=0 ./setup-grow-rootfs.sh

log "Resizing completed."

# Install docker
if ! command -v docker; then
  # If Docker is not installed, install it
  log "Installing docker from script..."
  sh ./get-docker.sh
fi

# Allow non-root docker access
if ! getent group docker; then
  log "Setting non-root access - adding to group..."
  # If the group doesn't exist, create it
  sudo groupadd docker
fi

log "USER: $USER"
# if ! groups | grep "docker"; then
#   # If the user is not a member, add them to the group
#   log "Adding user to group..."
#   sudo usermod -aG docker $USER
#   newgrp docker
# fi

# log "Printing groups"
# groups | grep "docker"

# Install Docker compose
log "Installing Docker-compose and xml-lint"

sudo apt install docker-compose -y
sudo apt-get update
sudo apt -y install libxml2-utils
sudo apt install nodejs -y
sudo apt install npm -y
# sudo apt-get install python -y

# Create Repos
log "Setting up repos..."
export PROJ_DIR=$(pwd)
export PROJ_VERSION="4.1.0"
DATASET=$(geni-get manifest | xmllint --xpath "string(//*[local-name()='data_item' and @name='emulab.net.parameter.dataset'])" -)
export CASE_DIR=${PROJ_DIR}/${DATASET}
mkdir -p ${CASE_DIR}

export SERVER_DIR=${PROJ_DIR}/server
cd ${SERVER_DIR}
npm init -y
npm install express -y
npm install moment -y
node server.js &

log "Exported variables: $PROJ_DIR, $PROJ_VERSION, $DATASET, $CASE_DIR"
cd ${PROJ_DIR}
# Get github repo
if ! ls | grep "container-dtc-nwp"; then
curl -SL https://github.com/NCAR/container-dtc-nwp/archive/refs/tags/v${PROJ_VERSION}.tar.gz | tar zxC . && mv container-dtc-nwp-${PROJ_VERSION} ./container-dtc-nwp
fi

# Get all dockers from HUB
log "Downloading images from Docker Hub..."
cd ${PROJ_DIR}
sudo docker pull dtcenter/wps_wrf:${PROJ_VERSION}
sudo docker pull dtcenter/gsi:${PROJ_VERSION}
sudo docker pull dtcenter/upp:${PROJ_VERSION}
sudo docker pull dtcenter/python:${PROJ_VERSION}
sudo docker pull dtcenter/nwp-container-met:${PROJ_VERSION}
sudo docker pull dtcenter/nwp-container-metviewer:${PROJ_VERSION}

if [ "$(sudo docker images | wc -l)" -ne 7 ]; then
  log "Error: The number of Docker images is not 7."
  exit 1  # Exit with an error code
fi

cd ${CASE_DIR}
mkdir -p wpsprd wrfprd gsiprd postprd pythonprd metprd metviewer/mysql
cd ${PROJ_DIR}
log "Preparation done. The script completed successfully."
