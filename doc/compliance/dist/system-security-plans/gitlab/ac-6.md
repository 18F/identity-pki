---
status:
  - c-implemented
  - c-documented
effort:
  - medium
---

# ac-6 - \[catalog\] Least Privilege

## Control Statement

The organization employs the principle of least privilege, allowing only authorized accesses for users (or processes acting on behalf of users) which are necessary to accomplish assigned tasks in accordance with organizational missions and business functions.

## Control Objective

Determine if the organization employs the principle of least privilege, allowing only authorized access for users (and processes acting on behalf of users) which are necessary to accomplish assigned tasks in accordance with organizational missions and business functions.

## Control guidance

Organizations employ least privilege for specific duties and information systems. The principle of least privilege is also applied to information system processes, ensuring that the processes operate at privilege levels no higher than necessary to accomplish required organizational missions/business functions. Organizations consider the creation of additional processes, roles, and information system accounts as necessary, to achieve least privilege. Organizations also apply least privilege to the development, implementation, and operation of organizational information systems.

______________________________________________________________________

## What is the solution and how is it implemented?

Accounts are managed in code. Least privilege is achieved through role-based
access to components. User privileges are assigned and removed dependent
upon role-based needs within the code.

______________________________________________________________________
