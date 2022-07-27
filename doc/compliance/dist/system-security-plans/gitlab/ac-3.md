---
status:
  - c-implemented
  - c-documented
---

# ac-3 - \[catalog\] Access Enforcement

## Control Statement

The information system enforces approved authorizations for logical access to
information and system resources in accordance with applicable access control
policies.

## Control Objective

Determine if the information system enforces approved authorizations for logical
access to information and system resources in accordance with applicable access
control policies.

## Control guidance

Access control policies (e.g., identity-based policies, role-based policies,
control matrices, cryptography) control access between active entities or
subjects (i.e., users or processes acting on behalf of users) and passive
entities or objects (e.g., devices, files, records, domains) in information
systems.

In addition to enforcing authorized access at the information system level and
recognizing that information systems can host many applications and services in
support of organizational missions and business operations, access enforcement
mechanisms can also be employed at the application and service level to provide
increased information security.

______________________________________________________________________

## What is the solution and how is it implemented?

Gitlab Environment:

Privileged and unprivileged accounts in the Gitlab environment are administred
with Role-Based Access Control. Users have different abilities depending on the
role they have in a particular group or project. Users authenticate to Gitlab by
authenticating to Login.gov.

______________________________________________________________________
