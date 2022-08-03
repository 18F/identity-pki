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

# look for the description item for ssm documents and dump the previous 2 lines
grep -B2 description ../terraform/app/ssm.tf
