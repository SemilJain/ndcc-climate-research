#!/bin/bash
cd /users/$USER
sudo cp -r /local/repository/* ./
uid=$(id -u $USER)
gid=$(id -g $USER)
sudo chown -R $uid:$gid ./
# chmod +x ./preparation.sh
bash preparation.sh

# chmod +x ./sandy.sh
bash sandy.sh

echo "Startup script Completed Successfully!!!"
