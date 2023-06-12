#!/bin/bash
#
# aws-password-reset v1.2
#
# 1. Generates a new random string
# 2  Sets the AWS console password using the random string
# 2. Copies new console password to clipboard
#
# Requires openssl to be installed in your PATH
#
# usage:
# aws-vault exec master -- bin/aws-password-reset.sh


debug=0

until [ `expr "$random_pass" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ];
do
 random_pass=$(openssl rand -base64 33)
done

if [[ $debug -ne 0 || ! $debug ]]; then
    echo "echo $random_pass" 1>&2
fi

if [[ -z $random_pass ]]; then
    echo "$pkg: failed to generate password" 1>&2
    exit 1
fi

aws iam update-login-profile --user-name $AWS_IAM_USER --password "$random_pass"

if [ $? -ne 0 ]; then
  echo "password was not changed successfully" 
  exit 1
else
  echo $random_pass | tr -d '[:blank:]' | pbcopy
fi

echo "Your new console password has been copied to the clipboard"
exit 0
