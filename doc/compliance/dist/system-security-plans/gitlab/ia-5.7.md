---
status:
  - c-implemented
  - c-documented
---

# ia-5.7 - \[catalog\] No Embedded Unencrypted Static Authenticators

## Control Statement

The organization ensures that unencrypted static authenticators are not embedded in applications or access scripts or stored on function keys.

## Control Objective

Determine if the organization ensures that unencrypted static authenticators are not:

- \[1\] embedded in applications;

- \[2\] embedded in access scripts; or

- \[3\] stored on function keys.

## Control guidance

Organizations exercise caution in determining whether embedded or stored authenticators are in encrypted or unencrypted form. If authenticators are used in the manner stored, then those representations are considered unencrypted authenticators. This is irrespective of whether that representation is perhaps an encrypted version of something else (e.g., a password).

______________________________________________________________________

## What is the solution and how is it implemented?

Under normal use static passwords stored in GitLab are not used or usable.
The Login.gov IdP is used for SSO in most cases, reducing the number of actively
used passwords in the GitLab component.

If Login.gov IdP is unavailable password authentication
with MFA may be enabled in GitLab for registered users after an authorized
operator has initiated temporary break-glass procedures.

Passwords that are stored in the Gitlab system are stored in a hashed/encrypted format.
Details on algorithm, stretching, and salting can be found here: https://docs.gitlab.com/ee/security/password_storage.html

______________________________________________________________________
