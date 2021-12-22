---
status:
  - c-implemented
  - c-documented
---

# ac-2.5 - \[catalog\] Inactivity Logout

## Control Statement

Require that users log out when organization-defined time period of expected inactivity or description of when to log out.

## Control guidance

Inactivity logout is behavior- or policy-based and requires users to take physical action to log out when they are expecting inactivity longer than the defined period. Automatic enforcement of inactivity logout is addressed by [AC-11](#ac-11).

______________________________________________________________________

## What is the solution and how is it implemented?

Login.gov does not have any policies requiring people to manually log
out of gitlab when they are done but their session has not yet expired.
It relies on the automatic controls in [AC-11](#ac-11).
______________________________________________________________________
