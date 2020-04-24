# terraform-sms

This directory contains terraform configuration used to set up the AWS accounts
used for our SMS/Voice services, using AWS Pinpoint.

It is used in the identity-sms-sandbox and identity-sms-prod accounts.


This is a module-style terraform subdirectory, which supplies all configuration
inside this directory and does not use identity-devops-private.

All terraform resources should go in [./module](./module). Environment-specific
variables can be supplied in the environment directories:

- [./sandbox](./sandbox)
- [./prod](./prod)
