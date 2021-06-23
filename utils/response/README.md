SecurityResponse is a python utility that quarantines a compromised EC2 instance. It does the following
- Removes instance from ASG, if the instance is part of an Auto Scaling Group
- Prepares an EBS snapshot of the instance
- Takes snapshot of the attached EBS volumes
- Gets instance's console screenshot and puts them into an S3 bucket
- Sets termination protection for the instance (exclusing spot instances as that is not supported on spot instances)
- Gets instance metadata
- Attaches instance to isolation security group. If isolation security group is not specified, it creates an isolation security group. 
- Creates a tag notifying that the instance is quarantined


The utility takes the following arguments:

'-i' -> instance_id, required=True
'-g' -> security group id (sgid), required=False
'-r' -> region, required=True
'-b' -> bucket required=True

Example:

$ python3 SecurityResponse.py -i i-06a0c710b7a697e82 -g sg-05075f7fe14d76a9a -r us-west-2 -b login-gov-idp-doc-capture.894947205914-us-west-2

