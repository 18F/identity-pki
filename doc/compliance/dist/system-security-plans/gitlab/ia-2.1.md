---
status:
  - c-implemented
  - c-documented
---

# ia-2.1 - \[catalog\] Network Access to Privileged Accounts

## Control Statement

The information system implements multifactor authentication for network access to privileged accounts.

## Control Objective

Determine if the information system implements multifactor authentication for network access to privileged accounts.

______________________________________________________________________

## What is the solution and how is it implemented?

All users, privileged and otherwise, require GSA VPN to gain network access, which requires MFA.  They also require login.gov to log in to the application, which uses MFA.  The Gitlab root account password is locked during bootstrapping, but in emergencies can be reset through using AWS SSM, which requires MFA.

______________________________________________________________________
