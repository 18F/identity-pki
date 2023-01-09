# terraform/guardrail

This directory contains the Terraform module that creates a ***Permission Boundary AWS IAM policy***, which is applied to all IAM roles in all of our AWS accounts.

As per the directory name, this policy serves as a baseline protection against any types of AWS API actions that could alter and/or destroy significant resources. In this case, 'significant' refers to any resource that, if removed/destroyed, could cause significant to catastrophic loss of data, access, etc. and/or cannot be replaced to prevent/recover from such losses, easily or at all.

Primarily, this policy prevents the destruction of the following resource types, for the `int` / `staging` / `prod` application environments:
- RDS DB instances
- Aurora DB clusters/global clusters
- DB snapshots
- DNS hosted zones

It also prevents:
- Destruction of the `login-gov-cloudtrail` Trail that exists in each AWS account
- Access to any actions/resources outside of `us-west-2`, `us-east-1`, and `us-east-2`

For additional security, *this policy **cannot** be altered by any IAM role that it is attached to*. If any updates/additions are required for the policy in the future, such changes can only be applied by the `root` account user.

For more information on Permission Boundaries, visit: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html


