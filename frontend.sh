#!/bin/bash

# installing dependencies
sudo apt install python3
wget https://bootstrap.pypa.io/get-pip.py
sudo python3 ./get-pip.py
yes | pip install Flask pygtail

# cloning web server repo
sudo git clone https://github.com/hamzalsheikh/climate-dashboard.git

# Get project directory
export PROJ_DIR=$(pwd)
PROJ_VERSION="4.1.0"
export DATASET=$(geni-get manifest | xmllint --xpath "string(//*[local-name()='data_item'])" -)
export CASE_DIR=${PROJ_DIR}/${DATASET}
mkdir -p ${CASE_DIR}

cd climate-dashboard
# running server
python3 main.py &

cd ..

sudo mkdir -p climate-dashboard/static/logs
# get log files
# pass name and path of log files
cat log-list.txt | while read line 
do
   # track each log line
   IFS=" " read -ra my_array <<< "$line"
   # get log line source dir
   if [ ${my_array[0]} == "root" ];
   then
      echo "log file in root directory $line "
      bash track-log.sh ${my_array[1]} &
   else
      echo "log file in case directory $line "
      bash track-log.sh "$CASE_DIR/${my_array[1]}" &
   fi
done

# Link result directory to server image directory
counter=0
max_counter=100
until [[ -d ${CASE_DIR}/pythonprd/ || $counter -ge $max_counter ]]
do
   echo "Waiting for the result directory  ${CASE_DIR}/pythonprd/ to be created..."
   let counter=counter+1
   sleep 5
done

sudo mkdir -p climate-dashboard/static/images
sudo ln -s ${CASE_DIR}/pythonprd/ $PROJ_DIR/climate-dashboard/static/images