#!/bin/bash

cp /local/repository/* ~/

cd

sudo chmod +x ~/preparation.sh
source ~/preparation.sh

sudo chmod +x ~/sandy.sh
source ~/sandy.sh

echo "Startup script Completed Successfully!!!"
