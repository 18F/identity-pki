# terraform-sms

This directory contains terraform configuration used to set up the AWS accounts
used for our SMS/Voice services, using AWS Pinpoint.

It is used in the login-sms-sandbox and login-sms-prod accounts.


This is a module-style terraform subdirectory, which supplies all configuration
inside this directory and does not use identity-devops-private.

All resources should go in [./module](./module).  Account-global resources
are in [../terraform-modules/account_pinpoint](../terraform-modules/account_pinpoint)
and are only included in the primary module for the account.

Environment-specific variables can be supplied in the environment directories:

- [./sandbox](./sandbox) - Sandbox - US-West-2 (includes account_pinpoint)
- [./sandbox-east](./sandbox-east) - Sandbox - US-East-1 
- [./prod](./prod) - Production - US-West-2 (includes account_pinpoint)
- [./prod-east](./prod-east) - Production - US-East-1
