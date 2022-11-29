---
status:
  - c-implemented
  - c-documented
effort:
  - medium
---

# ac-6.10 - \[catalog\] Prohibit Non-privileged Users from Executing Privileged Functions

## Control Statement

The information system prevents non-privileged users from executing privileged functions to include disabling, circumventing, or altering implemented security safeguards/countermeasures.

## Control Objective

Determine if the information system prevents non-privileged users from executing privileged functions to include:

- \[1\] disabling implemented security safeguards/countermeasures;

- \[2\] circumventing security safeguards/countermeasures; or

- \[3\] altering implemented security safeguards/countermeasures.

## Control guidance

Privileged functions include, for example, establishing information system accounts, performing system integrity checks, or administering cryptographic key management activities. Non-privileged users are individuals that do not possess appropriate authorizations. Circumventing intrusion detection and prevention mechanisms or malicious code protection mechanisms are examples of privileged functions that require protection from non-privileged users.

______________________________________________________________________

## What is the solution and how is it implemented?

Non-privileged access to Gitlab is limited to AppDev engineers.

Privileged access to Gitlab for the purpose of administration and implementing
or configuring security safeguards is restricted to only DevOps Engineers, and
requires PIV-based MFA from the GSA network.

______________________________________________________________________