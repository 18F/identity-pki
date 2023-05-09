---
status:
  - c-implemented
  - c-documented

effort:
  - medium
---

# ac-6.1 - \[catalog\] Authorize Access to Security Functions

## Control Statement

The organization explicitly authorizes access to organization-defined security functions (deployed in hardware, software, and firmware) and security-relevant information.

## Control Objective

Determine if the organization:

- \[1\] defines security-relevant information for which access must be explicitly authorized;

- \[2\] defines security functions deployed in:

  - \[a\] hardware;
  - \[b\] software;
  - \[c\] firmware;

- \[3\] explicitly authorizes access to:

  - \[a\] organization-defined security functions; and
  - \[b\] security-relevant information.

## Control guidance

Security functions include, for example, establishing system accounts,
configuring access authorizations (i.e., permissions, privileges), setting
events to be audited, and setting intrusion detection
parameters. Security-relevant information includes, for example, filtering rules
for routers/firewalls, cryptographic key management information, configuration
parameters for security services, and access control lists. Explicitly
authorized personnel include, for example, security administrators, system and
network administrators, system security officers, system maintenance personnel,
system programmers, and other privileged users.

______________________________________________________________________

## What is the solution and how is it implemented?

DevOps Engineers use CloudWatch logs to view and analyze GitLab audit logs.

Administrative GitLab access is granted on an as-needed basis to DevOps
engineers via commands executed in the AWS environment.

______________________________________________________________________
