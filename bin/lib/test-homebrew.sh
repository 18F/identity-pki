#!/bin/bash

test_homebrew_installed() {
	verbose=$1
	result=0
	description="homebrew is installed"
	explanation=""
	wiki_reference="https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#install-homebrew-and-required-packages"

	checking_message "$verbose" "$description"
	if ! command -v brew &> /dev/null
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"
}

test_hombrew_prefix_in_path() {
	verbose=$1
	result=0
	description="homebrew prefix is in PATH"
	explanation=""
	wiki_reference="https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#install-homebrew-and-required-packages"

	checking_message "$verbose" "$description"
	prefix=$(brew config | grep PREFIX | awk '{print $2}')
	if [[ ! $PATH =~ $prefix/bin ]]
	then
		result=1
	fi
	result_status "$verbose" $result

	error_message "$result" "$description" "$explanation" "$wiki_reference"
}


test_homebrew() {
	verbose=$1
	if test_homebrew_installed "$verbose"
	then
		test_hombrew_prefix_in_path "$verbose"
	fi
}
