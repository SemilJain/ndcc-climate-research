#!/bin/bash

# installing dependencies
sudo apt install python3-pip
pip3 install Flask pygtail

# cloning web server repo
sudo git clone https://github.com/hamzalsheikh/climate-dashboard.git
cd climate-dashboard

# get log files
sudo mkdir -p static/logs
sudo tail -f ../script_log.txt > static/logs/script_log.txt &

# running server
python3 main.py