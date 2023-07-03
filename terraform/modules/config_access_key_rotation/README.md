# config_access_key_rotation
This module monitors the IAM User's Access keys. It performs the following:

- Inactivate the access keys if it has not been rotated in the last 90days or if its age is beyond 100days 
- Sends a notification via email using SES, when the password age is between 80 and 90 days
- This implementation does not delete the access keys for user, thus for access keys with age older than 90days are all made inactive. However, with a slight modification to lambda, we should be able to delete the access keys that are older than 100 days(future implementation).

## Architecture Diagram: IAM Access Key Rotation Diagram

![Iam Access key Rotation](./diagrams/access_keys_rotation.png)

## AWS Resources 
It creates the following AWS Resources:
1. [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) with runtime "python3.9", with an IAM role with limited permissions to Cloudwatch Logs, SNS, Support.
2. [Event Rule](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/Create-CloudWatch-Events-Rule.html)

## Workflow
- Lambda is triggered by the Cloudwatch event rule at specific time of the day
- Lambda once getting triggered, it lists the IAM users in the Account and checks the access keys associated with the user. Evaluates the active access keys to see if the user has to be notified about the rotation or takes no action is the access keys are still new. 
- Lambda sends an email to the user once the keys are made inactive.
