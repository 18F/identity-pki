---
status:
  - c-implemented
  - c-documented
---

# ac-2 - \[catalog\] Account Management

## Control Statement

The organization:

- \[a\] Identifies and selects the following types of information system accounts to support organizational missions/business functions: organization-defined information system account types;

- \[b\] Assigns account managers for information system accounts;

- \[c\] Establishes conditions for group and role membership;

- \[d\] Specifies authorized users of the information system, group and role membership, and access authorizations (i.e., privileges) and other attributes (as required) for each account;

- \[e\] Requires approvals by organization-defined personnel or roles for requests to create information system accounts;

- \[f\] Creates, enables, modifies, disables, and removes information system accounts in accordance with organization-defined procedures or conditions;

- \[g\] Monitors the use of information system accounts;

- \[h\] Notifies account managers:

  - \[1\] When accounts are no longer required;
  - \[2\] When users are terminated or transferred; and
  - \[3\] When individual information system usage or need-to-know changes;

- \[i\] Authorizes access to the information system based on:

  - \[1\] A valid access authorization;
  - \[2\] Intended system usage; and
  - \[3\] Other attributes as required by the organization or associated missions/business functions;

- \[j\] Reviews accounts for compliance with account management requirements organization-defined frequency; and

- \[k\] Establishes a process for reissuing shared/group account credentials (if deployed) when individuals are removed from the group.

## Control Objective

Determine if the organization:

- \[a_obj\]

  - \[1\] defines information system account types to be identified and selected to support organizational missions/business functions;
  - \[2\] identifies and selects organization-defined information system account types to support organizational missions/business functions;

- \[b_obj\] assigns account managers for information system accounts;

- \[c_obj\] establishes conditions for group and role membership;

- \[d_obj\] specifies for each account (as required):

  - \[1\] authorized users of the information system;
  - \[2\] group and role membership;
  - \[3\] access authorizations (i.e., privileges);
  - \[4\] other attributes;

- \[e_obj\]

  - \[1\] defines personnel or roles required to approve requests to create information system accounts;
  - \[2\] requires approvals by organization-defined personnel or roles for requests to create information system accounts;

- \[f_obj\]

  - \[1\] defines procedures or conditions to:

    - \[a\] create information system accounts;
    - \[b\] enable information system accounts;
    - \[c\] modify information system accounts;
    - \[d\] disable information system accounts;
    - \[e\] remove information system accounts;

  - \[2\] in accordance with organization-defined procedures or conditions:

    - \[a\] creates information system accounts;
    - \[b\] enables information system accounts;
    - \[c\] modifies information system accounts;
    - \[d\] disables information system accounts;
    - \[e\] removes information system accounts;

- \[g_obj\] monitors the use of information system accounts;

- \[h_obj\] notifies account managers:

  - \[1_obj\] when accounts are no longer required;
  - \[2_obj\] when users are terminated or transferred;
  - \[3_obj\] when individual information system usage or need to know changes;

- \[i_obj\] authorizes access to the information system based on;

  - \[1_obj\] a valid access authorization;
  - \[2_obj\] intended system usage;
  - \[3_obj\] other attributes as required by the organization or associated missions/business functions;

- \[j_obj\]

  - \[1\] defines the frequency to review accounts for compliance with account management requirements;
  - \[2\] reviews accounts for compliance with account management requirements with the organization-defined frequency; and

- \[k_obj\] establishes a process for reissuing shared/group account credentials (if deployed) when individuals are removed from the group.

## Control guidance

Information system account types include, for example, individual, shared,
group, system, guest/anonymous, emergency, developer/manufacturer/vendor,
temporary, and service. Some of the account management requirements listed above
can be implemented by organizational information systems. The identification of
authorized users of the information system and the specification of access
privileges reflects the requirements in other security controls in the security
plan. Users requiring administrative privileges on information system accounts
receive additional scrutiny by appropriate organizational personnel (e.g.,
system owner, mission/business owner, or chief information security officer)
responsible for approving such accounts and privileged access.

Organizations may choose to define access privileges or other attributes by
account, by type of account, or a combination of both. Other attributes required
for authorizing access include, for example, restrictions on time-of-day,
day-of-week, and point-of-origin. In defining other account attributes,
organizations consider system-related requirements (e.g., scheduled maintenance,
system upgrades) and mission/business requirements, (e.g., time zone
differences, customer requirements, remote access to support travel
requirements). Failure to consider these factors could affect information system
availability.

Temporary and emergency accounts are accounts intended for short-term
use. Organizations establish temporary accounts as a part of normal account
activation procedures when there is a need for short-term accounts without the
demand for immediacy in account activation. Organizations establish emergency
accounts in response to crisis situations and with the need for rapid account
activation. Therefore, emergency account activation may bypass normal account
authorization processes. Emergency and temporary accounts are not to be confused
with infrequently used accounts (e.g., local logon accounts used for special
tasks defined by organizations or when network resources are unavailable). Such
accounts remain available and are not subject to automatic disabling or removal
dates. Conditions for disabling or deactivating accounts include, for example:
(i) when shared/group, emergency, or temporary accounts are no longer required;
or (ii) when individuals are transferred or terminated. Some types of
information system accounts may require specialized training.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

* Gitlab Accounts:

DevOps and AppDev Engineers authenticate to GitLab using the Login.gov identity
provider. Access is restricted to DevOps and AppDev Engineers.  Group, public,
guest/anonymous and temporary accounts are not permitted in this
environment. Accounts are managed with LG-developed scripts.

The Gitlab deployment and maintenance workflows are automated with LG-developed
scripts that may invoke the use of different tools based on the orchestration
function, such as the delivery of new Infrastructure as Code (IaC) or new Gitlab
application releases.

______________________________________________________________________

## Implementation b.

The DevOps Engineering Lead and DevOps Engineer roles perform account management
functions. The DevOps Engineering Lead determines which team members should have
the DevOps Engineering Lead and DevOps Engineer roles.

The AppDev Engineering Lead and AppDev Engineer roles perform account management
functions. The AppDev Engineering Lead determines which team members should have
the AppDev Engineering Lead and AppDev Engineer roles.

______________________________________________________________________

## Implementation c.

DevOps and AppDev team members are granted access to the Gitlab system based on
conditions A-F in Section 2(c) in the main SSP.

A DevOps Engineer is added to the `devops` group in Gitlab, based on an
established need to manage Gitlab.

An AppDev Engineer is added to the `appdev` group in Gitlab, based on an
established need to use Gitlab.

User group membership is restricted to the least privilege necessary for the
user to accomplish their assigned duties.

______________________________________________________________________

## Implementation d.

All Gitlab accounts employ Role Based Access Control (RBAC) as the access
control model. Roles approved to access the LG Gitlab system, along with
authorized privileges and functions, are described in Section 9.3 of the main
SSP, Types of Users.

______________________________________________________________________

## Implementation e.

This is described in the main SSP.

______________________________________________________________________

## Implementation f.

* Gitlab Accounts:

Conditions and procedures for creating LG system accounts are described in Parts c and e of this control. LG Supervisors are responsible for notifying the DevOps team of transfers, reassignments, terminations, need-to-know, or clearance changes. Notification occurs through an approved GSA communication method, such as GSA Gmail or 18F Slack, and the request is captured and tracked via a Gitlab issue. Detailed procedures for personnel terminations are described in Control PS-4.

______________________________________________________________________

## Implementation g.

All user access is tracked through logs collected by CloudWatch. Credential reports are reviewed monthly by the SOC Engineering team. 

______________________________________________________________________

## Implementation h.

* Gitlab Accounts:

LG Supervisors are ultimately responsible for notifying DevOps Engineers, or ensuring that DevOps Engineers are notified, regarding transfers, reassignments, terminations, need-to-know, or clearance changes. LG Supervisors notify DevOps Engineering via an approved GSA communication method, such as GSA Gmail or Slack, and the request is captured and tracked via a Gitlab issue. Detailed procedures for personnel terminations are described in PS-4. 

______________________________________________________________________

## Implementation i.

* Gitlab:

The System Owner is responsible for ensuring that non-privileged and privileged user access is granted based on job duties, currently limited to: AppDev Engineers with non-privileged access; DevOps Engineering Lead and DevOps Engineers with privileged access, SOC Engineers with read only access to audit records.

______________________________________________________________________

## Implementation j.

* Gitlab Accounts:

The GSA Information Security team and DevOps Engineering team review accounts for compliance with account management requirements quarterly. The DevOps Engineering team maintains a complete list of all authorized users of the information system, via source control.

______________________________________________________________________

## Implementation k.

Group accounts do not exist in any LG environment. The process for re-issuing shared account credentials when individuals are terminated, transferred, or reassigned is described in AC-2 (10).

______________________________________________________________________
