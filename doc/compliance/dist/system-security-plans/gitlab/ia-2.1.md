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

GitLab uses Login.gov for authentication which always requires MFA.  Additionally,
the GitLab integration with Login.gov is configured to require a phishing resistant MFA
method such as PIV/CAC, face or touch unlock, or hardware key.

Administrative access to GitLab UI/API requires GSA VPN access which also utilizes
MFA with PIV.

The GitLab root account password is locked during bootstrapping, but in emergencies can be reset through using AWS SSM, which requires MFA.

______________________________________________________________________
