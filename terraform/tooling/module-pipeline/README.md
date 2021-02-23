# Terraform Deployment Pipeline

This module will create a pipeline that does a terraform plan/apply on the
repo/branch/directory/account specified whenever it changes, 
and then run tests.  The codebuild
jobs will run in the auto-terraform-private subnet in the auto-terraform VPC
in the login-tooling account.

The global config of the subnet, VPC, firewall, IAM roles, etc, is all done
in `../module`.  This just does the individual codepipeline/codebuild pieces
for an individual deployment.
