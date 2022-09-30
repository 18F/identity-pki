#!/bin/bash

# simple script to list out the SSM documents avaliable to run

# debugging lines 
# uncomment next 2 lines for debugging
#set -x
#trap read debug

# debug error catching
set -euo pipefail

# get script directory
rundir="$(dirname "$0")"
# change to the script directory, since git directory names can vary
cd "$rundir"

# define the descriptor session documents, they are 2nd, 1st part of file is command documents
breakline="ssm_doc_map"

# find the command document lines and put them in an array
commands=($(sed -e "/$breakline/,\$d" ../terraform/app/ssm.tf| grep -B1 -e command | grep -v command| awk '{print $1}'|grep -v -- "^--$").)

# find descriptions and put in array
description=($(sed -e "/$breakline/,\$d" ../terraform/app/ssm.tf | awk '/command/{flag=1; next} flag && /description/{print substr($0, index($0,$3))}' | sed 's/ /_/g').)

# find the session document lines and put them in an array
sessions=($(sed -n -e "/$breakline/,\$p" ../terraform/app/ssm.tf| grep -B1 -e command | grep -v command| awk '{print $1}'|grep -v -- "^--$").)

# find sesssion descriptions
sdescription=($(sed -n -e "/$breakline/,\$p" ../terraform/app/ssm.tf | awk '/command/{flag=1; next} flag && /description/{print substr($0, index($0,$3))}' | sed 's/ /_/g').)

# check arrays are the same
[ ${#commands[@]} != ${#description[@]} ] && exit
[ ${#sessions[@]} != ${#sdescription[@]} ] && exit

echo "--- Command Documents ---"
number=("${#commands[@]}")
for (( i=0; i<$number; i++ ))
  do
    echo "${commands[$i]} - ${description[$i]}"| sed 's/_/ /g'
    echo "------"
  done
echo ""
echo "========="
echo ""
echo " --- Session Documents ---"
number=("${#sessions[@]}")
for (( i=0; i<$number; i++ ))
  do
    echo "${sessions[$i]} - ${sdescription[$i]}"| sed 's/_/ /g'
    echo "------"
  done
