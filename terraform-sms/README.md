# terraform-sms

This directory contains terraform configuration used to set up the AWS accounts
used for our SMS/Voice services, using AWS Pinpoint.

It is used in the login-sms-sandbox and login-sms-prod accounts.


This is a module-style terraform subdirectory, which supplies all configuration
inside this directory and does not use identity-devops-private.

Most resources should go in [./module](./module).  AWS account global
elements (IAM resources, S3 account policy, etc) should go in [./global](./global)

Environment-specific variables can be supplied in the environment directories:

- [./sandbox](./sandbox) - Sandbox - US-West-2 (includes global)
- [./sandbox-east](./sandbox-east) - Sandbox - US-East-1 
- [./prod](./prod) - Production - US-West-2 (includes global)
- [./prod-east](./prod-east) - Production - US-East-1
