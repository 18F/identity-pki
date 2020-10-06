#!/bin/bash
set -o nounset
set -o errexit

enable_macie() {
    echo -n "Enabling AWS Macie Service"
    TOKEN=$(openssl rand -hex 12)
    aws macie2 enable-macie --client-token $TOKEN --finding-publishing-frequency ONE_HOUR --status ENABLED
}

pause_macie() {
    echo "Pausing AWS Macie Service"
    TOKEN=$(openssl rand -hex 12)
    aws macie2 enable-macie --client-token $TOKEN --finding-publishing-frequency ONE_HOUR --status ENABLED
}

disable_macie() {
    echo "Disabling AWS Macie Service"
    aws macie2 disable-macie
}

usage() {
    echo "usage: macie.sh enable or macie.sh pause or macie.sh disable"
}

case ${1:-default} in
    enable)
        enable_macie
        ;;
    pause)
        pause_macie
        ;;
    disable)
        disable_macie
        ;;
    *)
        usage
        ;;    
esac
