---
status:
  - c-implemented
  - c-documented
---

# cp-9 - \[catalog\] Information System Backup

## Control Statement

The organization:

- \[a\] Conducts backups of user-level information contained in the information system organization-defined frequency consistent with recovery time and recovery point objectives;

- \[b\] Conducts backups of system-level information contained in the information system organization-defined frequency consistent with recovery time and recovery point objectives;

- \[c\] Conducts backups of information system documentation including security-related documentation organization-defined frequency consistent with recovery time and recovery point objectives; and

- \[d\] Protects the confidentiality, integrity, and availability of backup information at storage locations.

## Control Objective

Determine if the organization:

- \[a_obj\]

  - \[1\] defines a frequency, consistent with recovery time objectives and recovery point objectives as specified in the information system contingency plan, to conduct backups of user-level information contained in the information system;
  - \[2\] conducts backups of user-level information contained in the information system with the organization-defined frequency;

- \[b_obj\]

  - \[1\] defines a frequency, consistent with recovery time objectives and recovery point objectives as specified in the information system contingency plan, to conduct backups of system-level information contained in the information system;
  - \[2\] conducts backups of system-level information contained in the information system with the organization-defined frequency;

- \[c_obj\]

  - \[1\] defines a frequency, consistent with recovery time objectives and recovery point objectives as specified in the information system contingency plan, to conduct backups of information system documentation including security-related documentation;
  - \[2\] conducts backups of information system documentation, including security-related documentation, with the organization-defined frequency; and

- \[d_obj\] protects the confidentiality, integrity, and availability of backup information at storage locations.

## Control guidance

System-level information includes, for example, system-state information, operating system and application software, and licenses. User-level information includes any information other than system-level information. Mechanisms employed by organizations to protect the integrity of information system backups include, for example, digital signatures and cryptographic hashes. Protection of system backup information while in transit is beyond the scope of this control. Information system backups reflect the requirements in contingency plans as well as other organizational requirements for backing up information.

______________________________________________________________________

## What is the solution and how is it implemented?

______________________________________________________________________

## Implementation a.

GitLab user level information is backed up by both a full system
backup script as well as database snapshot backup using the same schedule as all items covered in the main Login.gov SSP.

The GitLab component aligns with CP-9, part A from the main Login.gov SSP where additional details can be found.

______________________________________________________________________

## Implementation b.

GitLab user level information is backed up by both a full system
backup script as well as database snapshot backup using the same schedule as all items covered in the main Login.gov SSP.

The GitLab component aligns with CP-9, part B from the main Login.gov SSP where additional details can be found.

______________________________________________________________________

## Implementation c.

The GitLab component aligns with CP-9, part C from the main Login.gov SSP.

______________________________________________________________________

## Implementation d.

The GitLab component aligns with CP-9, part D from the main Login.gov SSP.

______________________________________________________________________
