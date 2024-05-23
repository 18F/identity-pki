#!/bin/bash

test_ykman_installed() {
	verbose=$1
	result=0
	description="ykman is installed"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#install-homebrew-and-required-packages"

	checking_message "$verbose" "$description"
	if ! command -v ykman &> /dev/null
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_ykman_yubikey_plugged_in() {
	verbose=$1
	result=0
	description="ykman can see a yubikey"
	explanation=""
	wiki_reference=""

	checking_message "$verbose" "$description"
	if [[ ! $(ykman list | wc -l) -ge 1 ]]
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"

	return "$result"
}

test_ykman_yubikey_is_fips() {
	verbose=$1
	result=0
	description="yubikey is FIPS compliant"
	explanation=""
	wiki_reference=""

	checking_message "$verbose" "$description"
	if [[ ! $(ykman list) =~ 'FIPS' ]]
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"

	return "$result"
}

test_ykman_oath_account_total() {
	verbose=$1
	result=0
	description="ykman oath account total"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#install-homebrew-and-required-packages"

	checking_message "$verbose" "$description"
	if [[ $(ykman oath accounts list | wc -l) == 1 ]]
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_ykman_oath_account_name() {
	verbose=$1
	result=0
	description="ykman oath account in the expected format"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#configuring-a-mfa-authenticator"

	checking_message "$verbose" "$description"
	re="arn:aws:iam::340731855345:mfa/[a-zA-Z]*\.[a-zA-Z]*$"
	if [[ ! $(ykman oath accounts list) =~ $re ]]
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"

}

test_ykman() {
	verbose=$1
	if test_ykman_installed "$verbose"
	then
		if test_ykman_yubikey_plugged_in "$verbose"
		then
			test_ykman_yubikey_is_fips "$verbose"
			test_ykman_oath_account_total "$verbose"
			test_ykman_oath_account_name "$verbose"
		fi
	fi
}
