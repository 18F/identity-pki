The following steps are required in order to enable Amazon GuardDuty programatically

Configure the AWS account with the prerequisites to enable GuardDuty across all regions. 

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs.html

For convinience this directory has the AWSCloudFormationStackSetAdministrationRole.yml and AWSCloudFormationStackSetExecutionRole.yml 

Refer to the above URL to get the latest versions of AWSCloudFormationStackSetExecutionRole.yml and AWSCloudFormationStackSetAdministrationRole.yml 

Upon successful completion of the CFN as above. 

Deploy through CloudFormation Stacks the "enable-guardduty.template" , (which is in this directory)

Please Note: Security Token Service needs to be turned on in Regions where GuardDuty is activated. 
