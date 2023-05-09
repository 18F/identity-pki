---
status:
  - c-implemented
  - c-documented

---

# ia-4 - \[catalog\] Identifier Management

## Control Statement

The organization manages information system identifiers by:

- \[a\] Receiving authorization from organization-defined personnel or roles to assign an individual, group, role, or device identifier;

- \[b\] Selecting an identifier that identifies an individual, group, role, or device;

- \[c\] Assigning the identifier to the intended individual, group, role, or device;

- \[d\] Preventing reuse of identifiers for organization-defined time period; and

- \[e\] Disabling the identifier after organization-defined time period of inactivity.

## Control Objective

Determine if the organization manages information system identifiers by:

- \[a_obj\]

  - \[1\] defining personnel or roles from whom authorization must be received to assign:

    - \[a\] an individual identifier;
    - \[b\] a group identifier;
    - \[c\] a role identifier; and/or
    - \[d\] a device identifier;

  - \[2\] receiving authorization from organization-defined personnel or roles to assign:

    - \[a\] an individual identifier;
    - \[b\] a group identifier;
    - \[c\] a role identifier; and/or
    - \[d\] a device identifier;

- \[b_obj\] selecting an identifier that identifies:

  - \[1\] an individual;
  - \[2\] a group;
  - \[3\] a role; and/or
  - \[4\] a device;

- \[c_obj\] assigning the identifier to the intended:

  - \[1\] individual;
  - \[2\] group;
  - \[3\] role; and/or
  - \[4\] device;

- \[d_obj\]

  - \[1\] defining a time period for preventing reuse of identifiers;
  - \[2\] preventing reuse of identifiers for the organization-defined time period;

- \[e_obj\]

  - \[1\] defining a time period of inactivity to disable the identifier; and
  - \[2\] disabling the identifier after the organization-defined time period of inactivity.

## Control guidance

Common device identifiers include, for example, media access control (MAC), Internet protocol (IP) addresses, or device-unique token identifiers. Management of individual identifiers is not applicable to shared information system accounts (e.g., guest and anonymous accounts). Typically, individual identifiers are the user names of the information system accounts assigned to those individuals. In such instances, the account management activities of AC-2 use account names provided by IA-4. This control also addresses individual identifiers not necessarily associated with information system accounts (e.g., identifiers used in physical security control databases accessed by badge reader systems for access to information systems). Preventing reuse of identifiers implies preventing the assignment of previously used individual, group, role, or device identifiers to different individuals, groups, roles, or devices.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

Authorization is granted to assign unique identifiers to group and role identifiers by Login.gov leads and managers.

______________________________________________________________________

## Implementation b.

Groups and roles are selected for individuals and groups by Login.gov leads and managers.  

______________________________________________________________________

## Implementation c.

Groups and roles are assigned to individuals by Login.gov leads and mangers.

______________________________________________________________________

## Implementation d.

Reuse of individual user identifiers is disallowed upstream by Login.gov.

______________________________________________________________________

## Implementation e.

Individual user accounts are disabled in GitLab after a period of inactivity in order to free up licenses.  

______________________________________________________________________
