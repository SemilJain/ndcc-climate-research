#!/bin/bash

# sudo chmod +x /local/repository/preparation.sh
# source /local/repository/preparation.sh

# sudo chmod +x /local/repository/sandy.sh
# source /local/repository/sandy.sh
export USER="semil"
cd /users/$USER
sudo mkdir hello
sudo cp -r /local/repository/* ./
echo "Startup script Completed Successfully!!!"
