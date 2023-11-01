#!/bin/bash
export USER="semil"
cd /users/$USER
sudo mkdir hello
touch logs.txt
sudo cp -r /local/repository/* ./

sudo chmod +x ./preparation.sh
source ./preparation.sh

sudo chmod +x ./sandy.sh
source ./sandy.sh

echo "Startup script Completed Successfully!!!"
