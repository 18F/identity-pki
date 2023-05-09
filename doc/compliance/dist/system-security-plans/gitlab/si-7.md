---
status:
  - c-in-parent-ssp
  - c-documented
---

# si-7 - \[catalog\] Software, Firmware, and Information Integrity

## Control Statement

The organization employs integrity verification tools to detect unauthorized changes to organization-defined software, firmware, and information.

## Control Objective

Determine if the organization:

- \[1\]

  - \[a\] defines software requiring integrity verification tools to be employed to detect unauthorized changes;
  - \[b\] defines firmware requiring integrity verification tools to be employed to detect unauthorized changes;
  - \[c\] defines information requiring integrity verification tools to be employed to detect unauthorized changes;

- \[2\] employs integrity verification tools to detect unauthorized changes to organization-defined:

  - \[a\] software;
  - \[b\] firmware; and
  - \[c\] information.

## Control guidance

Unauthorized changes to software, firmware, and information can occur due to errors or malicious activity (e.g., tampering). Software includes, for example, operating systems (with key internal components such as kernels, drivers), middleware, and applications. Firmware includes, for example, the Basic Input Output System (BIOS). Information includes metadata such as security attributes associated with information. State-of-the-practice integrity-checking mechanisms (e.g., parity checks, cyclical redundancy checks, cryptographic hashes) and associated tools can automatically monitor the integrity of information systems and hosted applications.

______________________________________________________________________

## What is the solution and how is it implemented?

The GitLab component aligns with SI-7 from the main Login.gov SSP.

______________________________________________________________________
