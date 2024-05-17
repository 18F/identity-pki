#!/bin/bash

test_aws_vault_prompt_exists() {
	verbose=$1
	result=0
	description="Environment Variable AWS_VAULT_PROMPT Exists"
	explanation="AWS_VAULT_PROMPT controls the prompt driver aws-vault should use. In our case, ykman"
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#set-shell-variables-for-ykman-and-aws-vault"

	checking_message "$verbose" "$description"
	if [[ -z "${AWS_VAULT_PROMPT-}" ]]; then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" $wiki_reference


}

test_aws_vault_keychain_name_exists() {
	verbose=$1
	result=0
	description="Environment Variable AWS_VAULT_KEYCHAIN_NAME Exists"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#set-shell-variables-for-ykman-and-aws-vault"

	checking_message "$verbose" "$description"
	if [[ -z "${AWS_VAULT_KEYCHAIN_NAME-}" ]]; then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" $wiki_reference

}

test_ykman_oath_credentials_exists() {
	verbose=$1
	result=0
	description="Environment Variable YKMAN_OATH_CREDENTIAL Exists"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#set-shell-variables-for-ykman-and-aws-vault"

	checking_message "$verbose" "$description"
	if [[ -z "${YKMAN_OATH_CREDENTIAL-}" ]]; then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" $wiki_reference

	return "$result"
}

test_ykman_oath_credentials_expected_format() {
	verbose=$1
	result=0
	description="Environment Variable YKMAN_OATH_CREDENTIAL in the expected format"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#set-shell-variables-for-ykman-and-aws-vault"

	checking_message "$verbose" "$description"
	re="^arn:aws:iam::340731855345:mfa/[a-zA-Z]*\.[a-zA-Z]*$"
	if [[ ! "${YKMAN_OATH_CREDENTIAL}" =~ $re ]]; then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" $wiki_reference

}

test_login_iam_profile_exists() {
	verbose=$1
	result=0
	description="Environment Variable LOGIN_IAM_PROFILE Exists"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#set-shell-variables-for-ykman-and-aws-vault"

	checking_message "$verbose" "$description"
	if [[ -z "${LOGIN_IAM_PROFILE-}" ]]; then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" $wiki_reference


}

test_aws_iam_user_exists() {
	verbose=$1
	result=0
	description="Environment Variable AWS_IAM_USER Exists"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#set-shell-variables-for-ykman-and-aws-vault"

	checking_message "$verbose" "$description"
	if [[ -z "${AWS_IAM_USER-}" ]]; then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" $wiki_reference


}

test_gsa_username() {
	verbose=$1
	result=0
	description="Environment Variable GSA_USERNAME Exists"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#set-shell-variables-for-ykman-and-aws-vault"

	checking_message "$verbose" "$description"
	if [[ -z "${GSA_USERNAME-}" ]]; then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" $wiki_reference
}

test_environment_variables() {
	verbose=$1
	test_aws_vault_prompt_exists "$verbose"
	test_aws_vault_keychain_name_exists "$verbose"
	if test_ykman_oath_credentials_exists "$verbose"
	then
		test_ykman_oath_credentials_expected_format "$verbose"
	fi
	test_login_iam_profile_exists "$verbose"
	test_aws_iam_user_exists "$verbose"
	test_gsa_username "$verbose"
}
