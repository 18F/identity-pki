
Please find the script (deploywaf.sh) which will invoke aws cloudformation to execute and deploy AWS  WAF.
As noted it is a one-step operation, in that all you need to change is the value of the ALB log bucket name.
ParameterKey=CloudFrontAccessLogBucket,ParameterValue=”<alb-log-bucket>”
 
I have tested this successfully.
By default, Cloudformation rollback changes when the stack creation fails, however in this case.
 
For troubleshooting purposes, I have I have added a switch to disable rollback.
 
However feel free to revert to the default behavior as necessary.

========================================================================


This AWS CloudFormation template helps you provision the AWS WAF Security Automations stack without worrying about creating and configuring the underlying AWS infrastructure. This template creates an AWS Lambda function, an AWS WAF Web ACL, an Amazon S3 bucket, and an Amazon CloudWatch custom metric. 

You will be billed for the AWS resources used if you create a stack from this template. **NOTICE** Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved. Licensed under the Amazon Software License (the License). You may not use this file except in compliance with the License. A copy of the License is located at http://aws.amazon.com/asl/ or in the license file accompanying this file. 


This file is distributed on an AS IS BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and limitations under the License.
