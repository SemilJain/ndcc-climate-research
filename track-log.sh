#!/bin/bash
echo "track log!"
file=$1

# check if file has a wild card
if [[ $file == *"*"* ]]; then
  echo "wild card $file"
  while true; do
    files=( $file)  # attempt to expand the wildcard
    # we can customize this to the number of logs created per container
    if [ "${#files[@]}" -gt 2 ]; then
        echo "File found: ${file}"
        sudo ln -s ${file} $PROJ_DIR/climate-dashboard/static/logs/ 
        break
    else
        echo "Waiting for log files ${file} to exist..."
        sleep 1  # adjust the sleep duration as needed
    fi
  done

  exit
else
  echo "no wild card $file"
  # wait for file to be created
  counter=0
  max_counter=20
  until [[ -f $file || $counter -ge $max_counter ]]
  do
    echo "Waiting for the file $file to be created..."
    let counter=counter+1
    sleep 1
  done
  echo "creating symlink"
  sudo ln -s $PROJ_DIR/$file $PROJ_DIR/climate-dashboard/static/logs/
  exit

fi