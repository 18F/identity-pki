---
status:
  - c-implemented
  - c-in-parent-ssp
  - c-documented
---

# sa-8 - \[catalog\] Security Engineering Principles

## Control Statement

The organization applies information system security engineering principles in the specification, design, development, implementation, and modification of the information system.

## Control Objective

Determine if the organization applies information system security engineering principles in:

- \[1\] the specification of the information system;

- \[2\] the design of the information system;

- \[3\] the development of the information system;

- \[4\] the implementation of the information system; and

- \[5\] the modification of the information system.

## Control guidance

Organizations apply security engineering principles primarily to new development information systems or systems undergoing major upgrades. For legacy systems, organizations apply security engineering principles to system upgrades and modifications to the extent feasible, given the current state of hardware, software, and firmware within those systems. Security engineering principles include, for example: (i) developing layered protections; (ii) establishing sound security policy, architecture, and controls as the foundation for design; (iii) incorporating security requirements into the system development life cycle; (iv) delineating physical and logical security boundaries; (v) ensuring that system developers are trained on how to build secure software; (vi) tailoring security controls to meet organizational and operational needs; (vii) performing threat modeling to identify use cases, threat agents, attack vectors, and attack patterns as well as compensating controls and design patterns needed to mitigate risk; and (viii) reducing risk to acceptable levels, thus enabling informed risk management decisions.

______________________________________________________________________

## What is the solution and how is it implemented?

The Gitlab component uses sa-8 from the main login.gov SSP.

### Note to SSP editor:

Once GitLab is approved, we will migrate all private and infrastructure
repos to GitLab instead of GitHub, and GitLab will be used for
continuous integration instead of CircleCI.  So this probably will
just be a search/replace of github with gitlab.

______________________________________________________________________
