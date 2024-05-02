#!/bin/bash

function checking_message() {
	verbose=$1
	message=$2
	if [ "$verbose" == 0 ]
	then
		echo -n "Checking $message... "
	fi
}

function result_status() {
	verbose=$1
	result=$2
	if [ "$result" == 0 ] && [ "$verbose" == 0 ]
	then
		echo_green "OK"
	elif [ "$result" == 1 ] && [ "$verbose" == 0 ]
	then
		echo_red "FAILED"
	fi
}

# You shouldn't be calling this directly. Use warning_message or error_message
function message() {
	message_type=$1
	result=$2
	description=$3
	explanation=$4
	wiki_reference=$5
	if [ "$result" == 1 ]
	then
		if [ "$message_type" == "warning" ]
		then
			echo_yellow "Warning: $description test failed"
		elif [ "$message_type" == "error" ]
		then
			echo_red "Error: $description test failed"
		fi

		echo ""

		if [ -n "${explanation}" ]
		then
			echo "Explanation:"
			printf "\t%s\n\n" "$explanation"
		fi

		if [ -n "${wiki_reference}" ]
		then
			echo "Reference Documentation:"
			printf "\t%s\n\n" "$wiki_reference"
		fi
	fi

}

function warning_message() {
	result=$1
	description=$2
	explanation=${3:-}
	wiki_reference=${4:-}
	message "warning" "$result" "$description" "$explanation" "$wiki_reference"
}

function error_message() {
	result=$1
	description=$2
	explanation=${3:-}
	wiki_reference=${4:-}
	message "error" "$result" "$description" "$explanation" "$wiki_reference"
}
