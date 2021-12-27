---
status:
  - c-implemented
  - c-documented
---

# ac-2.1 - \[catalog\] Automated System Account Management

## Control Statement

The organization employs automated mechanisms to support the management of information system accounts.

## Control Objective

Determine if the organization employs automated mechanisms to support the management of information system accounts.

## Control guidance

The use of automated mechanisms can include, for example: using email or text messaging to automatically notify account managers when users are terminated or transferred; using the information system to monitor account usage; and using telephonic notification to report atypical system account usage.

______________________________________________________________________

## What is the solution and how is it implemented?

Users in gitlab are managed via the `sync.sh` script in
https://github.com/18F/identity-devops/tree/main/bin/users, which
adds and deletes the users in the system according to the
https://github.com/18F/identity-devops/blob/main/terraform/master/global/users.yaml
file, which is what is used to configure AWS IAM users elsewhere.

This script is run periodically by https://github.com/18F/identity-devops/blob/main/.gitlab-ci.yml

Job logs are kept which show what users (if any) are being added/deleted, as well as group
changes.

______________________________________________________________________
