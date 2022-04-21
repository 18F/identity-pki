# config_iam_password_rotation
This module monitors the IAM User's password used for Console Login. It performs the following for the users with Console Access enabled:
- Disables console login if the user has never logged in to the Console or not in the past 120 days
- Sends a notification to the sns topic, when the password age is between 90 and 100 days
- Disables the console login for users with password age more than 100 days(with active login activity)

## Architecture Diagram: IAM Password Rotation Diagram

![Iam Password Rotation](./diagrams/iam_password.png)

## AWS Resources 
It creates the following AWS Resources:
 1. [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) with runtime "python3.9", with an IAM role with limited permissions to Cloudwatch Logs, SNS, Support.
2. [SSM Document](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-ssm-docs.html)
3. [AWS Config Managed Rule](https://docs.aws.amazon.com/config/latest/developerguide/iam-password-policy.html)

## Workflow
- AWS Managed config rule "iam-password-policy" can be run at certain intervals(like every 24 hours).If the account password policy for IAM users does not meet the specified requirements indicated in the parameters the rule is NON_COMPLIANT and runs a ssm document as a part of autoremidiation. 
- The SSM document sends notification to the sns topic, to which our lambda is subscribed as well. 
- Lambda generates the IAM Credential report and calculates the IAM user's password age and the last time it was used to login. Currently, lambda is configured to disable console login if the user has never logged in or in more than 120 days(with console login being enabled). Also, for users with active login activity, the console login is disabled if password age is more than 100days. Users are notified everyday from 90th-100th day to rotate their password. 
- On a single run, the lambda either disables the user's console login or send notification to the users.