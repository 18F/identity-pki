#!/bin/bash

test_aws_vault_installed() {
	verbose=$1
	result=0
	description="aws-vault is installed"
	explanation=""
	wiki_reference="https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#install-homebrew-and-required-packages"

	checking_message "$verbose" "$description"
	if ! command -v aws-vault &> /dev/null
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"

	return $result
}

test_aws_vault_config_file_exists() {
	verbose=$1
	result=0
	description="aws-vault configuration file exists"
	explanation=""
	wiki_reference="https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#configure-aws-vault-with-aws-access-keys"

	checking_message "$verbose" "$description"
	if ! test -f ~/.aws/config
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"

	return $result
}

test_aws_vault_config_master_profile() {
	verbose=$1
	result=0
	description="aws-vault master profile exists"
	explanation=""
	wiki_reference="https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#configure-aws-vault-with-aws-access-keys"

	checking_message "$verbose" "$description"
	if ! grep -q master ~/.aws/config
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_aws_vault_config_sandbox_profiles() {
	verbose=$1
	result=0
	description="aws-vault sandbox profiles exists"
	explanation=""
	wiki_reference="https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#finish-aws-vault-setup"

	checking_message "$verbose" "$description"
	if ! grep -q sandbox ~/.aws/config
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_aws_vault_config_ca_bundle() {
	verbose=$1
	result=0
	description="aws-vault custom ca_bundle exists"
	explanation="Certain calls to AWS APIs can get man-in-the-middled by zscaler, causing issues. We recommend to create a custom ca_bundle that includes zscaler root certificates."
	wiki_reference="https://github.com/18F/identity-devops/wiki/Working-around-%5BSSL:-CERTIFICATE_VERIFY_FAILED%5D-error"

	checking_message "$verbose" "$description"
	if ! grep -q ca_bundle ~/.aws/config
	then
		result=1
	fi
	result_status "$verbose" $result

	warning_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_aws_vault() {
	verbose=$1
	if test_aws_vault_installed "$verbose"
	then
		if test_aws_vault_config_file_exists "$verbose"
		then
			test_aws_vault_config_master_profile "$verbose"
			test_aws_vault_config_sandbox_profiles "$verbose"
			test_aws_vault_config_ca_bundle "$verbose"
		fi
		
	fi
}
