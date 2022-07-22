---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp

needs-params:
  - ac-7_prm_3
---

# ac-7 - \[catalog\] Unsuccessful Logon Attempts

## Control Statement

The information system:

- \[a\] Enforces a limit of organization-defined number consecutive invalid logon attempts by a user during a organization-defined time period; and

- \[b\] Automatically No value found when the maximum number of unsuccessful attempts is exceeded.

## Control Objective

Determine if:

- \[a_obj\]

  - \[1\] the organization defines the number of consecutive invalid logon attempts allowed to the information system by a user during an organization-defined time period;
  - \[2\] the organization defines the time period allowed by a user of the information system for an organization-defined number of consecutive invalid logon attempts;
  - \[3\] the information system enforces a limit of organization-defined number of consecutive invalid logon attempts by a user during an organization-defined time period;

- \[b_obj\]

  - \[1\] the organization defines account/node lockout time period or logon delay algorithm to be automatically enforced by the information system when the maximum number of unsuccessful logon attempts is exceeded;
  - \[2\] the information system, when the maximum number of unsuccessful logon attempts is exceeded, automatically:

    - \[a\] locks the account/node for the organization-defined time period;
    - \[b\] locks the account/node until released by an administrator; or
    - \[c\] delays next logon prompt according to the organization-defined delay algorithm.

## Control guidance

This control applies regardless of whether the logon occurs via a local or network connection. Due to the potential for denial of service, automatic lockouts initiated by information systems are usually temporary and automatically release after a predetermined time period established by organizations. If a delay algorithm is selected, organizations may choose to employ different algorithms for different information system components based on the capabilities of those components. Responses to unsuccessful logon attempts may be implemented at both the operating system and the application levels.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

As Gitlab uses Login.gov application accounts for its authentication, this is
covered in the Login.gov SSP, AC-7 Part A, "Application Accounts".

______________________________________________________________________

## Implementation b.

As Gitlab uses Login.gov application accounts for its authentication, this is
covered in the Login.gov SSP, AC-7 Part B, "Application Accounts".

______________________________________________________________________
