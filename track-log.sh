#!/bin/bash
echo "track log!"
echo $1

IFS=" " read -ra log_files <<< "$1"
  for file in ${log_files[@]}; do
  # wait till file creation
    until [[ -f $file ]]
    do
      echo "Waiting for the file $1 to be created..."
      sleep 1
    done
    
    sudo tail -f $file > "climate-dashboard/static/logs/${file##*/}" &
  done

# to-do kill process when done

tailpid=$!

# wait for sometime
sleep 25

# now kill the tail process
sudo kill $tailpid