#!/bin/bash

cp /local/repository/* ~/

cd

sudo chmod +x preparation.sh
source ./preparation.sh

sudo chmod +x ${DATASET}.sh
source ./${DATASET}.sh

echo "Startup script Completed Successfully!!!"
