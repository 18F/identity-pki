# monitor_limits

This module sends a notification to an existing sns topic when the usage for AWS services supported by [Trusted Advisor](https://aws.amazon.com/premiumsupport/ta-iam/) is above 80% of allocated quota. AWS Trusted Advisor is a global AWS service thus this  module has to be created in us-east-1 region but it will monitor the usage in all AWS regions.

It creates a lambda function(python) along with an IAM role and permission to access AWS Services, CloudWatch and Support. Two lambda functions are created.
First one is responsible for running "describe_trusted_advisor_checks" api in "us-east-1" region.

Second one is responsible for checking the status of recent refresh and look for services that have the usage status as Yellow or Red, then notify the sns topic.

Note: Resources are created in the region passed in the variable var.aws_region but api calls from within the lambda are run in us-east-1 region as Trusted Advisor is a global service.

## Prerequistes:
1) SNS topic to send notification

## AWS Resources 
It creates the following AWS Resources:
1. [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) with runtime "python3.9", with an IAM role with limited permissions to Cloudwatch Logs, Support.
2. [CW Events Rule](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/Create-CloudWatch-Events-Rule.html)

## Architecture Diagram: Service Limit Monitoring Diagram

![Service Limit Monitoring Diagram](./diagrams/trusted_advisor.png)
   
## Usage:

    module "limit_check_lambda" {
         source                        = "../modules/monitor_svc_limit"
	    refresher_trigger_schedule     = var.refresher_trigger_schedule
	    monitor_trigger_schedule       = var.monitor_trigger_schedule
         aws_region                    = var.aws_region
	    sns_topic                      = var.sns_topic
    }

 **Inputs**
 |   Name                  |  Description                                                          | Type   |  Default      | Required |
 | ---------------------   | --------------------------------------------------------------------- | ------ | ------------- | -------- |
 | aws_region              | AWS Region                                                            | string |  us-east-1    | Yes      |
 | filename                | Filename for the lambda code 			   | string |               | No      |
 | function_input          | JSON input that will be sent to Lambda function                       | json   |               | No       |
 | function_name           | Name to assign to the lambda					   | string  |              | Yes      |
 | lambda_handler          | Handler for Lambda function                                           | string |  |   No |
 | lambda_runtime          | Runtime for the Lambda function                                       | string | python3.9      |  No      |
 | lambda_timeout          | Timeout Value for Lambda                                              | number |     180        | No	|
 | monitor_trigger_schedule | Frequency of invoking TA Monitor Lambda from CW event rule           | string |cron(10 14 * * ? *)| Yes      |
 | refresher_trigger_schedule   | Frequency of invoking TA Refresher Lambda from CW event rule                       | string |cron(0 14 * * ? *)| Yes     |
 | sns_topic| SNS topic to send information when Service Usage is above 80% of allocated limit                                  | string |                |  Yes     |

  **Outputs**
  |   Name                            |  Description                                |                                                         
  | ------------------------------    | ------------------------------------------- |                                                     
  | ta_refresher_lambda_arn              | Arn of Lambda Function refreshing Trusted Advisor                        |
  | ta_monitor_lambda_arn               | Arn of Lambda function monitoring Trusted Advisor               |

