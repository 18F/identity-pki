---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp

needs-params:
  - cm-8.3_prm_3
effort:
  - medium
---

# cm-8.3 - \[catalog\] Automated Unauthorized Component Detection

## Control Statement

The organization:

- \[a\] Employs automated mechanisms organization-defined frequency to detect the presence of unauthorized hardware, software, and firmware components within the information system; and

- \[b\] Takes the following actions when unauthorized components are detected: No value found.

## Control Objective

Determine if the organization:

- \[a_obj\]

  - \[1\] defines the frequency to employ automated mechanisms to detect the presence of unauthorized:

    - \[a\] hardware components within the information system;
    - \[b\] software components within the information system;
    - \[c\] firmware components within the information system;

  - \[2\] employs automated mechanisms with the organization-defined frequency to detect the presence of unauthorized:

    - \[a\] hardware components within the information system;
    - \[b\] software components within the information system;
    - \[c\] firmware components within the information system;

- \[b_obj\]

  - \[1\] defines personnel or roles to be notified when unauthorized components are detected;
  - \[2\] takes one or more of the following actions when unauthorized components are detected:

    - \[a\] disables network access by such components;
    - \[b\] isolates the components; and/or
    - \[c\] notifies organization-defined personnel or roles.

## Control guidance

This control enhancement is applied in addition to the monitoring for unauthorized remote connections and mobile devices. Monitoring for unauthorized system components may be accomplished on an ongoing basis or by the periodic scanning of systems for that purpose. Automated mechanisms can be implemented within information systems or in other separate devices. Isolation can be achieved, for example, by placing unauthorized information system components in separate domains or subnets or otherwise quarantining such components. This type of component isolation is commonly referred to as sandboxing.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation (a)

The GitLab component aligns with CM-8(3), part A from the main Login.gov SSP.

______________________________________________________________________

## Implementation (b)

The GitLab component aligns with CM-8(3), part B from the main Login.gov SSP.

______________________________________________________________________