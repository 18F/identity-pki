#!/bin/sh
#
# This script sets up the environment variables so that terraform and
# the tests can know how to run and what to test.

help_me() {
    cat >&2 << EOM
    
Usage: ${0} <env_name> <idp_hostname> [-deorRtvh]

Runs all tests in the test directory, designed to be run with two
arguments <env_name> <idp_hostname>. Below are optional flags that
can be specified. Environment and IDP hostname can be set with
either the flags or as positional parameters to maintain backwards
compatibilty with existing automation. Positional parameters take
precedent over ones set with flags.

  -d : hostname for the idp instance in the environment, defaults to idp.<env_name>.identitysandbox.gov
  -e : environment to run terratests against
  -f : path to a newline seperated key=value configuration file to load into the tests environment before running
  -o : hostname for the idp origin instance in the environment, defaults to idp.origin.<env_name>.identitysandbox.gov
  -r : aws region the terraform backend buckets are in, defaults to us-west-2
  -R : enable or disable the long running recycle test by passing true or false, defaults to true
  -t : specify the path to a single test file to run instead of running all
  -v : environment variable you want as part of the run in format VAR_NAME=VAR_VALUE, can pass multiple
  -h : Displays this help

EOM
  exit 0
}

check_var() {
  if [ -z $1 ]
  then
    return 1
  else
    return 0
  fi
}

# Parse flags and positional parameters for script and setup environment
flags() {
  script_args=()
  while [ $OPTIND -le "$#" ]
  do 
    if getopts ":e::d::f::o::r::R::t::v:h" opt
    then
      case "$opt" in
        d) 
          export IDP_HOSTNAME="${OPTARG}" >&2 ;;
        e) 
          export ENV_NAME="${OPTARG}" >&2 ;;
        f)
          while read line
          do
            export "${line}"
          done < "${OPTARG}" ;;
        o) 
          export IDP_ORIGIN_HOSTNAME=${OPTARG} >&2 ;;
        r) 
          export REGION="${OPTARG}" >&2 ;;
        R) 
          export RECYCLE=${OPTARG} >&2 ;;
        t) 
          export TEST_NAME="${OPTARG}" >&2 ;;
        v) 
          export "${OPTARG}" >&2 ;;
        h) 
          help_me ;;
        \?)
          echo "Invalid option: -$OPTARG" >&2
          exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2
           exit 1 ;;
        *) help_me ;;
      esac
    else
      script_args+=("${!OPTIND}")
      ((OPTIND++))
    fi
  done
  if (( ${#script_args[@]} ))
  then 
    echo "Setting environment name, and domain name from positional arguments"
    export ENV_NAME="${script_args[0]}"
    export IDP_HOSTNAME="${script_args[1]}"
  else
    echo "${script_args[@]}"
    echo "No positional parameters"
  fi
}


if [[ $# -eq o ]]
then
  help_me
else
  flags "$@"
fi

# Check variables and assign defaults as needed
if ! check_var $ENV_NAME
then
  echo "Please set an terraform environment to run against with -e <env_name>, or as positional argument one"
  exit 1
else
  echo "Running against ${ENV_NAME} environment"
fi
if ! check_var $IDP_ORIGIN_HOSTNAME
then
  export IDP_ORIGIN_HOSTNAME="idp.origin.${ENV_NAME}.identitysandbox.gov"
  echo "Using default setting for IDP_ORIGIN_DOMAIN_NAME: ${IDP_ORIGIN_HOSTNAME}"
else
  echo "Using IDP_ORIGIN_DOMAIN_NAME: ${IDP_ORIGIN_DOMAIN_NAME}"
fi
if ! check_var $IDP_HOSTNAME
then
  export IDP_HOSTNAME="idp.${ENV_NAME}.identitysandbox.gov"
  echo "Using default setting for IDP_DOMAIN_NAME: ${IDP_HOSTNAME}"
else
  echo "Using IDP_DOMAIN_NAME: ${IDP_DOMAIN_NAME}"
fi
if ! check_var $RECYCLE
then
  export RECYCLE="TRUE"
  echo "Running long running asg recycle test"
else
  echo "Not running long running asg recycle test RECYCLE: ${RECYCLE}"
fi
if ! check_var $REGION
then
  export REGION="us-west-2"
  echo "Using default setting for REGION: ${REGION}"
else
  echo "Running in REGION: ${REGION}"
fi
if ! check_var $ACCOUNT_ID
then
  export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
  echo "Using detected ACCOUNT_ID: ${ACCOUNT_ID}"
else
  echo "Using ACCOUNT_ID: ${ACCOUNT_ID}"
fi

# Check if a single test should be run, otherwise run the whole suite
if [ -z $TEST_NAME ]
then
  echo "Running entire test suite"
  go test -v -timeout 60m
else
  echo "Running test ${TEST_NAME}"
  go test -v -timeout 60m -run ${TEST_NAME}
fi
