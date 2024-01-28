#!/bin/bash

# installing dependencies
sudo apt install python3-pip
pip3 install Flask pygtail

# cloning web server repo
sudo git clone https://github.com/hamzalsheikh/climate-dashboard.git



# Get project directory
export PROJ_DIR=$(pwd)
PROJ_VERSION="4.1.0"
export DATASET=$(geni-get manifest | xmllint --xpath "string(//*[local-name()='data_item'])" -)
export CASE_DIR=${PROJ_DIR}/${DATASET}
mkdir -p ${CASE_DIR}

sudo mkdir -p climate-dashboard/static/logs

# get log files
# pass name and path of log files
cat log-list.txt | while read line 
do
   # run a process for each log file
   echo $line
   bash track-log.sh $line  &
done

# Link result directory to server image directory
ln -s ${CASE_DIR}/pythonprd/ $PROJ_DIR/climate-dashboard/static/images

cd climate-dashboard
# running server
python3 main.py