#!/bin/bash
. "$(dirname "$0")/lib/common.sh"

needs_arg() { if [ -z "$OPTARG" ]; then raise "No arg for --$OPT option"; fi; }

TASK_LIST='update open'
declare {SANDBOX_AMIS,PROD_AMIS}=
DATA=()

while getopts luoh-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  
  case "$OPT" in
    sb|sandbox-base)  needs_arg; SANDBOX_AMIS+="base_$OPTARG " ;;
    sr|sandbox-rails) needs_arg; SANDBOX_AMIS+="rails_$OPTARG " ;;
    pb|prod-base)  needs_arg; PROD_AMIS+="base_$OPTARG" ;;
    pr|prod-rails) needs_arg; PROD_AMIS+="rails_$OPTARG" ;;
    l) TASK_LIST=                         ;;
    u) TASK_LIST='update'                 ;;
    o) TASK_LIST='open'                   ;;
    h) man_page ;;
    ??* )          raise "Illegal option --$OPT" ;;  # bad long option
    ? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

for TYPE in base rails ; do
  [[ $SANDBOX_AMIS =~ $TYPE ]] || SANDBOX_AMIS+="${TYPE} "
  [[ $PROD_AMIS =~ $TYPE ]] || PROD_AMIS+="${TYPE} "
done

echo ${SANDBOX_AMIS}
echo ${PROD_AMIS}
echo $TASK_LIST

exit