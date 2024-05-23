#!/bin/bash

test_identity_base_image_exists() {
	verbose=$1
	result=0
	description="identity-base-image is locally available"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#clone-git-repos"

	checking_message "$verbose" "$description"
	GIT_TOPLEVEL=$(git rev-parse --show-toplevel | sed -E 's/\/[^/]*$/\//')
	if ! test -d "$GIT_TOPLEVEL/identity-base-image"
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_identity_cookbooks_exists() {
	verbose=$1
	result=0
	description="identity-cookbooks is locally available"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#clone-git-repos"

	checking_message "$verbose" "$description"
	GIT_TOPLEVEL=$(git rev-parse --show-toplevel | sed -E 's/\/[^/]*$/\//')
	if ! test -d "$GIT_TOPLEVEL/identity-cookbooks"
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_identity_devops_private_exists() {
	verbose=$1
	result=0
	description="identity-devops-private is locally available"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#clone-git-repos"

	checking_message "$verbose" "$description"
	GIT_TOPLEVEL=$(git rev-parse --show-toplevel | sed -E 's/\/[^/]*$/\//')
	if ! test -d "$GIT_TOPLEVEL/identity-devops-private"
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_identity_terraform_exists() {
	verbose=$1
	result=0
	description="identity-terraform is locally available"
	explanation=""
	wiki_reference="https://gitlab.login.gov/lg/identity-devops/-/wikis/Setting-Up-your-Login.gov-Infrastructure-Configuration#clone-git-repos"

	checking_message "$verbose" "$description"
	GIT_TOPLEVEL=$(git rev-parse --show-toplevel | sed -E 's/\/[^/]*$/\//')
	if ! test -d "$GIT_TOPLEVEL/identity-terraform"
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_local_repos() {
	verbose=$1
	test_identity_base_image_exists "$verbose"
	test_identity_cookbooks_exists "$verbose"
	test_identity_devops_private_exists "$verbose"
	test_identity_terraform_exists "$verbose"
}
