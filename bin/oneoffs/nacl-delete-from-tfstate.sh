#!/bin/bash
set -euo pipefail

# shellcheck source=/dev/null
. "$(dirname "$0")/../lib/common.sh"

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") NACL_ID

Delete all Network ACL rule resources from terraform state for the specified
network ACL NACL_ID.

See https://github.com/18F/identity-devops/tree/master/doc/technical/operations/nacl-hacks.md

This is useful for recovering from terraform bugs where it can't cope with
rules that are present in the state file but deleted in the real AWS resources.

If you are seeing a terraform error message like this:

     * aws_network_acl_rule.myrule: Expected to find one Network ACL, got: []*ec2.NetworkAcl(nil)

Then this script may be what you need.

+-----------------------------------------------------------------------------+
|   ** DANGER **  ** DANGER **  ** DANGER **  ** DANGER **  ** DANGER **      |
|   THIS IS EXTREMELY DANGEROUS AND COULD RESULT IN COMPLETELY SCREWING UP    |
|   YOUR TERRAFORM STATE. YOU HAVE BEEN WARNED!                               |
+-----------------------------------------------------------------------------+

This script must be run with a current working directory that has a .terraform/
directory under it. So if you are running ./deploy ... terraform-app, then you
would \`cd terraform-app\` before starting this script.

EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

NACL_ID="$1"

echo_blue "Current terraform NACL resources:"
run terraform state list | grep network_acl

if [[ $NACL_ID != acl-* ]]; then
    echo_red "Doesn't look like a acl-* NACL_ID: '$NACL_ID'"
    exit 2
fi

echo_blue "Looking for aws_network_acl_rule resources with id == '$NACL_ID'"

matching=()

for line in $(run terraform state list | grep -w aws_network_acl_rule); do
    output="$(run terraform state show "$line")"
    if grep -E "^network_acl_id += $NACL_ID" <<< "$output" >/dev/null; then
        echo >&2 "Found matching network acl rule:"
        echo >&2 "$output"
        matching+=("$line")
    fi
done

if [ "${matching[#]}" -eq 0 ]; then
    echo_blue "No matching rules found"
    exit
fi

echo_yellow "Will delete these rules from TF state: ${matching[*]}"

prompt_yn "Continue?"

for match in "${matching[@]}"; do
    run terraform state rm "$match"
done

echo_blue 'All done!'

# shellcheck disable=SC2016
echo_blue 'Run an apply or `terraform remote push` to save state changes'
