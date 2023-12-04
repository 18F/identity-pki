### Setting Up New Accounts \ VPCs

 - Add the main_vpc module 
 - Obtain an unassociated EIP from the available pool
 - Import that EIP into module.main_vpc.aws_eip.main
 - Set the IP address of the EIP in the top-level variables.tf as var.image_build_nat_eip
 - Do a full Terraform run

```
EIPS=(`aws ec2 describe-addresses --output text --query 'Addresses[?AssociationId==null].PublicIp'`)
tf-deploy imagebuild/[insert env name here] import module.main_native.aws_eip.main $EIPS[1]
[add EIP IP in variables.tf]
tf-deploy imagebuild/[insert account name here] apply

```
