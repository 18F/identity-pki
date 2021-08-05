This repo has a set of Utilities which can be classified as the "Break Glass Utilities"

SecurityResponse

SecurityResponse is a python script that quarantines a compromised EC2 instance. It does the following
- Removes instance from ASG, if the instance is part of an Auto Scaling Group
- Prepares an EBS snapshot of the instance
- Takes snapshot of the attached EBS volumes
- Gets instance's console screenshot and puts them into an S3 bucket
- Sets termination protection for the instance (exclusing spot instances as that is not supported on spot instances)
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

SecurityResponse.py [-h] -i IID -g SGID [-r REGION] [-b BUCKET] [-t TOPIC]
SecurityResponse.py: the following arguments are required: -i/--iid, -g/--sgid

Example:
$ ./SecurityResponse.py -i i-06a0c710b7a697e82 -g sg-05075f7fe14d76a9a 

VPC Kill Switch 

VPC kill switch, cuts the connectivity of the VPC to the Internet. This is the BIG RED BUTTON utility, that should only be used when VPC needs to be disconnected from the Big I in case of a major catastrophe. PLEASE USE THIS UTILITY IN WORST CASE SCENARIO ONLY.

Usage:

vpc_kill_switch.py [-h] [-v VPCID] [-r REGION]
the -r is already defaulted to us-west-2.  -v is the VPC ID whose connectivity you want to disconnect from the Big I

./vpc_kill_switch.py -v vpc-1234567890123
