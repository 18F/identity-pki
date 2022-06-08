---
status:
  - c-implemented
  - c-documented
needs-params:
  - sc-6_prm_2
---

# sc-6 - \[catalog\] Resource Availability

## Control Statement

The information system protects the availability of resources by allocating organization-defined resources by No value found.

## Control Objective

Determine if:

- \[1\] the organization defines resources to be allocated to protect the availability of resources;

- \[2\] the organization defines security safeguards to be employed to protect the availability of resources;

- \[3\] the information system protects the availability of resources by allocating organization-defined resources by one or more of the following:

  - \[a\] priority;
  - \[b\] quota; and/or
  - \[c\] organization-defined safeguards.

## Control guidance

Priority protection helps prevent lower-priority processes from delaying or interfering with the information system servicing any higher-priority processes. Quotas prevent users or processes from obtaining more than predetermined amounts of resources. This control does not apply to information system components for which there are only single users/roles.

______________________________________________________________________

## What is the solution and how is it implemented?

To maintain service availability, Gitlab uses AWS Availability Zones and Elastic Load Balancing, along with real-time resource monitoring and alerting.

______________________________________________________________________
