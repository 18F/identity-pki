---
status:
  - c-inherited
  - c-documented
---

# ia-5.1 - \[catalog\] Password-based Authentication

## Control Statement

The information system, for password-based authentication:

- \[a\] Enforces minimum password complexity of organization-defined requirements for case sensitivity, number of characters, mix of upper-case letters, lower-case letters, numbers, and special characters, including minimum requirements for each type;

- \[b\] Enforces at least the following number of changed characters when new passwords are created: organization-defined number;

- \[c\] Stores and transmits only cryptographically-protected passwords;

- \[d\] Enforces password minimum and maximum lifetime restrictions of organization-defined numbers for lifetime minimum, lifetime maximum;

- \[e\] Prohibits password reuse for organization-defined number generations; and

- \[f\] Allows the use of a temporary password for system logons with an immediate change to a permanent password.

## Control Objective

Determine if, for password-based authentication:

- \[a_obj\]

  - \[1\] the organization defines requirements for case sensitivity;
  - \[2\] the organization defines requirements for number of characters;
  - \[3\] the organization defines requirements for the mix of upper-case letters, lower-case letters, numbers and special characters;
  - \[4\] the organization defines minimum requirements for each type of character;
  - \[5\] the information system enforces minimum password complexity of organization-defined requirements for case sensitivity, number of characters, mix of upper-case letters, lower-case letters, numbers, and special characters, including minimum requirements for each type;

- \[b_obj\]

  - \[1\] the organization defines a minimum number of changed characters to be enforced when new passwords are created;
  - \[2\] the information system enforces at least the organization-defined minimum number of characters that must be changed when new passwords are created;

- \[c_obj\] the information system stores and transmits only encrypted representations of passwords;

- \[d_obj\]

  - \[1\] the organization defines numbers for password minimum lifetime restrictions to be enforced for passwords;
  - \[2\] the organization defines numbers for password maximum lifetime restrictions to be enforced for passwords;
  - \[3\] the information system enforces password minimum lifetime restrictions of organization-defined numbers for lifetime minimum;
  - \[4\] the information system enforces password maximum lifetime restrictions of organization-defined numbers for lifetime maximum;

- \[e_obj\]

  - \[1\] the organization defines the number of password generations to be prohibited from password reuse;
  - \[2\] the information system prohibits password reuse for the organization-defined number of generations; and

- \[f_obj\] the information system allows the use of a temporary password for system logons with an immediate change to a permanent password.

## Control guidance

This control enhancement applies to single-factor authentication of individuals using passwords as individual or group authenticators, and in a similar manner, when passwords are part of multifactor authenticators. This control enhancement does not apply when passwords are used to unlock hardware authenticators (e.g., Personal Identity Verification cards). The implementation of such password mechanisms may not meet all of the requirements in the enhancement. Cryptographically-protected passwords include, for example, encrypted versions of passwords and one-way cryptographic hashes of passwords. The number of changed characters refers to the number of changes required with respect to the total number of positions in the current password. Password lifetime restrictions do not apply to temporary passwords. To mitigate certain brute force attacks against passwords, organizations may also consider salting passwords.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation (a)

Security controls for passwords relating to case sensitivity, length, content, and complexity are all managed upstream by Login.gov. 
The GitLab component aligns with IA-5(1), part A from the main Login.gov SSP.

______________________________________________________________________

## Implementation (b)

Security controls for passwords relating to minimum changes between old and new passwords are managed upstream by Login.gov. 
The GitLab component aligns with IA-5(1), part B from the main Login.gov SSP.

______________________________________________________________________

## Implementation (c)

Security controls for passwords relating to encrypted storage and transmission are managed upstream by Login.gov. 
The GitLab component aligns with IA-5(1), part C from the main Login.gov SSP.

______________________________________________________________________

## Implementation (d)

Security controls for passwords relating to minimum or maximum lifetimes are managed upstream by Login.gov. 
The GitLab component aligns with IA-5(1), part D from the main Login.gov SSP.

______________________________________________________________________

## Implementation (e)

Security controls for passwords relating to generational reuse are managed upstream by Login.gov. 
The GitLab component aligns with IA-5(1), part E from the main Login.gov SSP.

______________________________________________________________________

## Implementation (f)

Security controls for passwords relating to temporary passwords and required changes are managed upstream by Login.gov. 
The GitLab component aligns with IA-5(1), part F from the main Login.gov SSP.

______________________________________________________________________
