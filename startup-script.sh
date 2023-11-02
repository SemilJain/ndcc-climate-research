#!/bin/bash
cd /users/$USER
touch logs.txt
sudo cp -r /local/repository/* ./

chmod +x ./preparation.sh
sh preparation.sh

chmod +x ./sandy.sh
sh sandy.sh

echo "Startup script Completed Successfully!!!"
