---
status:
  - c-implemented
  - c-documented

---

# ac-6.2 - \[catalog\] Non-privileged Access for Nonsecurity Functions

## Control Statement

The organization requires that users of information system accounts, or roles, with access to organization-defined security functions or security-relevant information, use non-privileged accounts or roles, when accessing nonsecurity functions.

## Control Objective

Determine if the organization:

- \[1\] defines security functions or security-relevant information to which users of information system accounts, or roles, have access; and

- \[2\] requires that users of information system accounts, or roles, with access to organization-defined security functions or security-relevant information, use non-privileged accounts, or roles, when accessing nonsecurity functions.

## Control guidance

This control enhancement limits exposure when operating from within privileged accounts or roles. The inclusion of roles addresses situations where organizations implement access control policies such as role-based access control and where a change of role provides the same degree of assurance in the change of access authorizations for both the user and all processes acting on behalf of the user as would be provided by a change between a privileged and non-privileged account.

______________________________________________________________________

## What is the solution and how is it implemented?

GitLab restricts accounts with privileged access (DevOps Engineers) from accessing administrative functions by default. To access administrative functions, administrators must re-authenticate with MFA to assume an administrative role.

______________________________________________________________________
