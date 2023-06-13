---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp

effort:
  - medium
---

# au-5 - \[catalog\] Response to Audit Processing Failures

## Control Statement

The information system:

- \[a\] Alerts organization-defined personnel or roles in the event of an audit processing failure; and

- \[b\] Takes the following additional actions: organization-defined actions to be taken (e.g., shut down information system, overwrite oldest audit records, stop generating audit records).

## Control Objective

Determine if:

- \[a_obj\]

  - \[1\] the organization defines the personnel or roles to be alerted in the event of an audit processing failure;
  - \[2\] the information system alerts the organization-defined personnel or roles in the event of an audit processing failure;

- \[b_obj\]

  - \[1\] the organization defines additional actions to be taken (e.g., shutdown information system, overwrite oldest audit records, stop generating audit records) in the event of an audit processing failure; and
  - \[2\] the information system takes the additional organization-defined actions in the event of an audit processing failure.

## Control guidance

Audit processing failures include, for example, software/hardware errors, failures in the audit capturing mechanisms, and audit storage capacity being reached or exceeded. Organizations may choose to define additional actions for different audit processing failures (e.g., by type, by location, by severity, or a combination of such factors). This control applies to each audit data storage repository (i.e., distinct information system component where audit records are stored), the total audit storage capacity of organizations (i.e., all audit data storage repositories combined), or both.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

The GitLab component aligns with AU-5, part A from the main Login.gov SSP.

______________________________________________________________________

## Implementation b.

The GitLab component aligns with AU-5, part B from the main Login.gov SSP.

______________________________________________________________________