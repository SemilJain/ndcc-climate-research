#!/bin/bash
cd /users/$USER
sudo cp -r /local/repository/* ./

# chmod +x ./preparation.sh
bash preparation.sh

# chmod +x ./sandy.sh
bash sandy.sh

echo "Startup script Completed Successfully!!!"
