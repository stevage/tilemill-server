#!/bin/bash
touch nohup.out
nohup bash ./update-data.sh &
# store the process id of the nohup process in a variable
CHPID=$!        

# whenever ctrl-c is pressed, kill the nohup process before exiting
trap "echo 'Abandoning import.' && kill -9 $CHPID" INT

tail -f nohup.out
