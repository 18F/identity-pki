This repo has a set of Utilities which can be classified as the "Break Glass Utilities"

**quarantine-instance**

quarantine-instance is a python script that quarantines a compromised EC2 instance. It does the following
- Removes instance from ASG, if the instance is part of an Auto Scaling Group
- Prepares an EBS snapshot of the instance
- Takes snapshot of the attached EBS volumes
- Gets instance's console screenshot and puts them into an S3 bucket
- Sets termination protection for the instance (excluding spot instances as that is not supported on spot instances)
- Gets instance metadata
- Attaches instance to isolation security group. If isolation security group is not specified, it creates an isolation security group. 
- Creates a tag notifying that the instance is quarantined

The script takes the following arguments:

'-i' -> instance_id, required=True

'-g' -> security group id (sgid), required=True

'-r' -> region, required=False, default=us-west-2

'-b' -> bucket required=False, default=login-gov.quarantine-ec2."+ACCOUNT_ID+"-"+us-west-2

'-t' -> SNS topic arn, required=False default=arn:aws:sns:"+us-west-2+":"+ACCOUNT_ID+":slack-events


Usage:

./quarantine-instance [-h] -i IID -g SGID [-r REGION] [-b BUCKET] [-t TOPIC]
./quarantine-instance: The following arguments are required: -i/--iid, -g/--sgid

**PLEASE NOTE: You need to be logged in as the admin of your environment to run the script**

Example:
*$ aws-vault exec sandbox-admin*
*$ ./quarantine-instance -i i-06a0c710b7a697e82 -g sg-05075f7fe14d76a9a* 

**VPC Kill Switch** 

VPC kill switch, cuts the connectivity of the VPC to the Internet. This is the BIG RED BUTTON utility, that should only be used when VPC needs to be disconnected from the Big I in case of a major catastrophe. PLEASE USE THIS UTILITY IN WORST CASE SCENARIO ONLY.

Usage:

vpc-kill-switch [-h] [-v VPCID] [-vn vpcname] [-r REGION]

-v is the VPC ID whose connectivity you want to disconnect from the Big I
-vn is the VPC Name whose connectivity you want to disconnect from the Big I
-r is the Region which defaults to us-west-2

You can specify either the VPC ID or VPC Name 

**PLEASE NOTE: You need to be logged in as the admin of your environment to run the script**
*$ aws-vault exec sandbox-admin* 

**Example:**
*./vpc-kill-switch -v vpc-1234567890123*
*./vpc-kill-switch -vn login-acme-vpc*

**Emergency-Stop Utility** 

The Emergency Stop, queries route tables in a VPC and removes the quad zero entry in those route tables pointing to the Internet Gateway. This will effectively cut on publically facing subnets access to the Big I. You need to be an admin for the environment to be able to run the utility. You can re-add the route table entry by running the Terraform apply again and it will restore the quad zero entries. 

Usage:

emergency-stop [-v VPCID] [-r REGION]

-v is the VPC ID whose connectivity you want to disconnect from the Big I
-r is the Region which defaults to us-west-2

**PLEASE NOTE: You need to be logged in as the admin of your environment to run the script**
*$ aws-vault exec sandbox-admin* 

**Example:**
*./emergency-stop -v vpc-1234567890123*