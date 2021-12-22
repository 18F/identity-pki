---
status:
  - c-implemented
  - c-documented
---

# ac-2.4 - \[catalog\] Automated Audit Actions

## Control Statement

The information system automatically audits account creation, modification, enabling, disabling, and removal actions, and notifies organization-defined personnel or roles.

## Control Objective

Determine if:

- \[1\] the information system automatically audits the following account actions:

  - \[a\] creation;
  - \[b\] modification;
  - \[c\] enabling;
  - \[d\] disabling;
  - \[e\] removal;

- \[2\] the organization defines personnel or roles to be notified of the following account actions:

  - \[a\] creation;
  - \[b\] modification;
  - \[c\] enabling;
  - \[d\] disabling;
  - \[e\] removal;

- \[3\] the information system notifies organization-defined personnel or roles of the following account actions:

  - \[a\] creation;
  - \[b\] modification;
  - \[c\] enabling;
  - \[d\] disabling; and
  - \[e\] removal.

______________________________________________________________________

## What is the solution and how is it implemented?

Users in gitlab are managed via the `sync.sh` script in
https://github.com/18F/identity-devops/tree/main/bin/users, which
adds and deletes the users in the system according to the
https://github.com/18F/identity-devops/blob/main/terraform/master/global/users.yaml
file, which is what is used to configure AWS IAM users elsewhere.

This script is run periodically by https://github.com/18F/identity-devops/blob/main/.gitlab-ci.yml

Job logs are kept by gitlab which show what users (if any) are
being added/deleted, as well as group changes.

______________________________________________________________________
