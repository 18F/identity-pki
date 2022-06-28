---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp
effort:
  - medium
---

# au-2 - \[catalog\] Audit Events

## Control Statement

The organization:

- \[a\] Determines that the information system is capable of auditing the following events: organization-defined auditable events (see parent SSP for organization-defined auditable events);

- \[b\] Coordinates the security audit function with other organizational entities requiring audit-related information to enhance mutual support and to help guide the selection of auditable events;

- \[c\] Provides a rationale for why the auditable events are deemed to be adequate to support after-the-fact investigations of security incidents; and

- \[d\] Determines that the following events are to be audited within the information system: organization-defined audited events (the subset of the auditable events defined in AU-2 a.) along with the frequency of (or situation requiring) auditing for each identified event.

## Control Objective

Determine if the organization:

- \[a_obj\]

  - \[1\] defines the auditable events that the information system must be capable of auditing;
  - \[2\] determines that the information system is capable of auditing organization-defined auditable events;

- \[b_obj\] coordinates the security audit function with other organizational entities requiring audit-related information to enhance mutual support and to help guide the selection of auditable events;

- \[c_obj\] provides a rationale for why the auditable events are deemed to be adequate to support after-the-fact investigations of security incidents;

- \[d_obj\]

  - \[1\] defines the subset of auditable events defined in AU-2a that are to be audited within the information system;
  - \[2\] determines that the subset of auditable events defined in AU-2a are to be audited within the information system; and
  - \[3\] determines the frequency of (or situation requiring) auditing for each identified event.

## Control guidance

An event is any observable occurrence in an organizational information system. Organizations identify audit events as those events which are significant and relevant to the security of information systems and the environments in which those systems operate in order to meet specific and ongoing audit needs. Audit events can include, for example, password changes, failed logons, or failed accesses related to information systems, administrative privilege usage, PIV credential usage, or third-party credential usage. In determining the set of auditable events, organizations consider the auditing appropriate for each of the security controls to be implemented. To balance auditing requirements with other information system needs, this control also requires identifying that subset of auditable events that are audited at a given point in time. For example, organizations may determine that information systems must have the capability to log every file access both successful and unsuccessful, but not activate that capability except for specific circumstances due to the potential burden on system performance. Auditing requirements, including the need for auditable events, may be referenced in other security controls and control enhancements. Organizations also include auditable events that are required by applicable federal laws, Executive Orders, directives, policies, regulations, and standards. Audit records can be generated at various levels of abstraction, including at the packet level as information traverses the network. Selecting the appropriate level of abstraction is a critical aspect of an audit capability and can facilitate the identification of root causes to problems. Organizations consider in the definition of auditable events, the auditing necessary to cover related events such as the steps in distributed, transaction-based processes (e.g., processes that are distributed across multiple organizations) and actions that occur in service-oriented architectures.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

See parent SSP.

______________________________________________________________________

## Implementation b.

See parent SSP.

______________________________________________________________________

## Implementation c.

See parent SSP.

______________________________________________________________________

## Implementation d.

See parent SSP.

______________________________________________________________________
