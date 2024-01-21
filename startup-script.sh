#!/bin/bash
cd /users/$USER
sudo cp -r /local/repository/* ./
uid=$(id -u $USER)
gid=$(id -g $USER)
sudo chown -R $uid:$gid ./
# chmod +x ./preparation.sh
bash preparation.sh

DATASET=$(geni-get manifest | xmllint --xpath "string(//*[local-name()='data_item'])" -)

# chmod +x ./sandy.sh
bash "$DATASET.sh"

echo "Startup script Completed Successfully!!!"
