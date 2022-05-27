---
status:
  - c-implemented
  - c-documented
effort:
  - medium
---

# ia-7 - \[catalog\] Cryptographic Module Authentication

## Control Statement

The information system implements mechanisms for authentication to a cryptographic module that meet the requirements of applicable federal laws, Executive Orders, directives, policies, regulations, standards, and guidance for such authentication.

## Control Objective

Determine if the information system implements mechanisms for authentication to a cryptographic module that meet the requirements of applicable federal laws, Executive Orders, directives, policies, regulations, standards, and guidance for such authentication.

## Control guidance

Authentication mechanisms may be required within a cryptographic module to authenticate an operator accessing the module and to verify that the operator is authorized to assume the requested role and perform services within that role.

______________________________________________________________________

## What is the solution and how is it implemented?

Gitlab implements recent and compliant versions of OpenSSL, Ruby and Golang, and can be configured to achieve FIPS 140-2 or 140-3 per statements made by Gitlab (https://gitlab.com/groups/gitlab-org/-/epics/5104).

______________________________________________________________________
