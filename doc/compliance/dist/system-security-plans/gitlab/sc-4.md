---
status:
  - c-implemented
  - c-documented
---

# sc-4 - \[catalog\] Information in Shared Resources

## Control Statement

The information system prevents unauthorized and unintended information transfer via shared system resources.

## Control Objective

Determine if the information system prevents unauthorized and unintended information transfer via shared system resources.

## Control guidance

This control prevents information, including encrypted representations of information, produced by the actions of prior users/roles (or the actions of processes acting on behalf of prior users/roles) from being available to any current users/roles (or current processes) that obtain access to shared system resources (e.g., registers, main memory, hard disks) after those resources have been released back to information systems. The control of information in shared resources is also commonly referred to as object reuse and residual information protection. This control does not address: (i) information remanence which refers to residual representation of data that has been nominally erased or removed; (ii) covert channels (including storage and/or timing channels) where shared resources are manipulated to violate information flow restrictions; or (iii) components within information systems for which there are only single users/roles.

______________________________________________________________________

## What is the solution and how is it implemented?

Gitlab prevents unauthorized and unintended information transfer via shared system resources by separating the Gitlab source code management system processes from Gitlab runner processes. Specifically, any build, test and other Gitlab runner activities are sequestered from the Gitlab source code management system processes by placing all runner or CICD process on separate virtual machines which use separate security groups, and dedicated web proxies.

______________________________________________________________________
