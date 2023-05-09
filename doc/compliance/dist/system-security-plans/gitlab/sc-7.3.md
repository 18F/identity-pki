---
status:
  - c-implemented
  - c-documented
---

# sc-7.3 - \[catalog\] Access Points

## Control Statement

The organization limits the number of external network connections to the information system.

## Control Objective

Determine if the organization limits the number of external network connections to the information system.

## Control guidance

Limiting the number of external network connections facilitates more comprehensive monitoring of inbound and outbound communications traffic. The Trusted Internet Connection (TIC) initiative is an example of limiting the number of external network connections.

______________________________________________________________________

## What is the solution and how is it implemented?

GitLab limits the number of external network connections; the only access points visible on a public network are AWS load balancers.

______________________________________________________________________
