#!/bin/bash
echo $1

# to-do check if dir or file ?

# wait till file creation
until [ -f $1 ]
do
  echo "Waiting for the file to be created..."
  sleep 1
done

sudo tail -f $1 > "climate-dashboard/static/logs/$1"

# to-do kill process when done