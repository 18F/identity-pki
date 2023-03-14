#!/bin/bash
#
set -euo pipefail


. "$(git rev-parse --show-toplevel)/bin/lib/common.sh"

usage() {
    cat >&2 <<EOM

Usage: ${0} -u [USER]

Flags (optional):
  -h      : Display help menu
  -u USER : The target AWS User to remove all access

EOM
}

AWS_PROFILE=
AV_PROFILE=
groups=()

while getopts u:h opt; do
    case $opt in
    u) USER="${OPTARG}" ;;
    *) usage && exit 1 ;;
    esac
done

main() {
    validate_input_and_settings
    remove_console_access
    deactive_access_keys
    remove_attached_policies
    remove_groups
    revoke_sessions
}

validate_input_and_settings() {

    verify_root_repo

    get_iam "master" "global" "FullAdministrator"

    if ! ave -r aws iam get-user --user-name "$USER" 1>/dev/null; then
            raise "ERROR: User not found."
    fi

    prompt_yn "Revoke all access for ${USER}?"
}

revoke_sessions() {

    roles=()

    echo -n "Collecting Role Information. This may take a moment."

    for g in "${groups[@]}"; do
        group_policy=()
        group_policy=($(
                ave -r aws iam list-attached-group-policies \
                --group-name "$g" \
                --query "AttachedPolicies[*].PolicyArn" \
                | jq -r '.[]'
            ))

        for policy in "${group_policy[@]}"; do
            version=$(
                ave -r aws iam get-policy \
                    --policy-arn "$policy" \
                    --query "Policy.DefaultVersionId" | tr -d '"'
            )

            roles+=($(
                ave -r aws iam get-policy-version \
                    --policy-arn "$policy" \
                    --version-id "$version" \
                    --query "PolicyVersion.Document.Statement[*].Resource" \
                    --output text
            ))

            echo -n "."
        done
    done

    echo

    #Remove duplicates roles defined by multiple policies
    roles=($(echo "${roles[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    datetime_now=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

    revoke_policy=$(
        jq -n \
            --arg TokenTime "$datetime_now" \
            '{
                    "Version": "2012-10-17",
                    "Statement": [
                    {
                        "Effect":"Deny",
                        "Action":["*"],
                        "Resource":["*"],
                        "Condition":
                        {
                            "DateLessThan":
                            {
                                "aws:TokenIssueTime":$TokenTime
                            }
                        }
                    }
                    ]
                }'
    )

    for role in "${roles[@]}"; do

        local ACCT_NUM=$(echo "$role" | cut -d ":" -f 5)

        get_iam_by_account_num "$ACCT_NUM" "FullAdministrator"

        role_name=$(echo "$role" | cut -d "/" -f 2)

        if ! ave -r aws iam list-account-aliases 1>/dev/null ;then
            echo_red "Failed to revoke sessions for $role"
            continue
        fi

        account_alias=$(
            ave -r aws iam list-account-aliases \
                --output text |
                awk '{print $2}'
        )

        #Revoke Sessions

        echo_blue "Revoking All Sessions for Role $role_name in $account_alias"
        if ! ave -r aws iam put-role-policy \
            --role-name "$role_name" \
            --policy-name AWSRevokeOlderSessions \
            --policy-document "$revoke_policy" \
            1>/dev/null;then
                    echo_red "Failed to revoke sessions for role $role_name in $account_alias"
                    continue
        fi

    done

    echo_green "All sessions have been revoked."

}

remove_attached_policies() {
    attached_policies=()
    attached_policies+=($(
        ave -r aws iam list-attached-user-policies \
            --user-name "$USER" \
            --query "AttachedPolicies[*].PolicyArn" \
            --output text
        )
    )

    if [ ${#attached_policies[@]} -eq 0 ];then
        echo_blue "No attached policies found."
        return
    fi

    for policy in "${attached_policies[@]}"; do
        echo_blue "Removing Policy $policy from user $USER"
        ave -r aws iam detach-user-policy \
            --user-name "$USER" \
            --policy-arn "$policy" \
            1>/dev/null
    done
}

remove_console_access() {
    echo_blue "Removing console access for $USER"
    if ! ave -r aws iam delete-login-profile --user-name "$USER" 1>/dev/null ;then
        echo_red "Failed to delete login profile. The account might not have one."
        return
    fi
}

deactive_access_keys() {
    read -r -a access_keys <<<"$(
    ave -r aws iam list-access-keys \
        --user-name "$USER" \
        --query "AccessKeyMetadata[*].AccessKeyId" \
        | jq -r '.[]'
    )"

    for a in "${access_keys[@]}"; do
        echo_blue "Deactivating Access Key $a from user $USER"
        ave -r aws iam update-access-key \
            --user-name "$USER" \
            --status "Inactive" \
            --access-key-id "$a" 1>/dev/null
    done
}

remove_groups() {

    read -r -a groups <<<"$(
    ave -r aws iam list-groups-for-user \
        --user-name "$USER" \
        --query "Groups[*].GroupName" \
        | jq -r '.[]'
    )"

    for g in "${groups[@]}"; do
        echo_blue "Removing $USER from group $g"
        ave -r aws iam remove-user-from-group \
            --user-name "$USER" \
            --group-name "$g" 1>/dev/null
    done
}

main
