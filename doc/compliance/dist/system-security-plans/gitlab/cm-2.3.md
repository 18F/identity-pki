---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp

---

# cm-2.3 - \[catalog\] Retention of Previous Configurations

## Control Statement

The organization retains organization-defined previous versions of baseline configurations of the information system to support rollback.

## Control Objective

Determine if the organization:

- \[1\] defines previous versions of baseline configurations of the information system to be retained to support rollback; and

- \[2\] retains organization-defined previous versions of baseline configurations of the information system to support rollback.

## Control guidance

Retaining previous versions of baseline configurations to support rollback may include, for example, hardware, software, firmware, configuration files, and configuration records.

______________________________________________________________________

## What is the solution and how is it implemented?

The GitLab component aligns with CM-2(3) from the main Login.gov SSP. 

In addition, GitLab implements git, which will be used to configure
our GitLab infrastructure, and git is a source code control system
which keeps track of all changes to this data.  It also has
regular backups that can be restored.

______________________________________________________________________
