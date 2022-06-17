---
status:
  - c-inherited
  - c-not-documented
effort:
  - medium
---

# ia-5 - \[catalog\] Authenticator Management

## Control Statement

The organization manages information system authenticators by:

- \[a\] Verifying, as part of the initial authenticator distribution, the identity of the individual, group, role, or device receiving the authenticator;

- \[b\] Establishing initial authenticator content for authenticators defined by the organization;

- \[c\] Ensuring that authenticators have sufficient strength of mechanism for their intended use;

- \[d\] Establishing and implementing administrative procedures for initial authenticator distribution, for lost/compromised or damaged authenticators, and for revoking authenticators;

- \[e\] Changing default content of authenticators prior to information system installation;

- \[f\] Establishing minimum and maximum lifetime restrictions and reuse conditions for authenticators;

- \[g\] Changing/refreshing authenticators organization-defined time period by authenticator type;

- \[h\] Protecting authenticator content from unauthorized disclosure and modification;

- \[i\] Requiring individuals to take, and having devices implement, specific security safeguards to protect authenticators; and

- \[j\] Changing authenticators for group/role accounts when membership to those accounts changes.

## Control Objective

Determine if the organization manages information system authenticators by:

- \[a_obj\] verifying, as part of the initial authenticator distribution, the identity of:

  - \[1\] the individual receiving the authenticator;
  - \[2\] the group receiving the authenticator;
  - \[3\] the role receiving the authenticator; and/or
  - \[4\] the device receiving the authenticator;

- \[b_obj\] establishing initial authenticator content for authenticators defined by the organization;

- \[c_obj\] ensuring that authenticators have sufficient strength of mechanism for their intended use;

- \[d_obj\]

  - \[1\] establishing and implementing administrative procedures for initial authenticator distribution;
  - \[2\] establishing and implementing administrative procedures for lost/compromised or damaged authenticators;
  - \[3\] establishing and implementing administrative procedures for revoking authenticators;

- \[e_obj\] changing default content of authenticators prior to information system installation;

- \[f_obj\]

  - \[1\] establishing minimum lifetime restrictions for authenticators;
  - \[2\] establishing maximum lifetime restrictions for authenticators;
  - \[3\] establishing reuse conditions for authenticators;

- \[g_obj\]

  - \[1\] defining a time period (by authenticator type) for changing/refreshing authenticators;
  - \[2\] changing/refreshing authenticators with the organization-defined time period by authenticator type;

- \[h_obj\] protecting authenticator content from unauthorized:

  - \[1\] disclosure;
  - \[2\] modification;

- \[i_obj\]

  - \[1\] requiring individuals to take specific security safeguards to protect authenticators;
  - \[2\] having devices implement specific security safeguards to protect authenticators; and

- \[j_obj\] changing authenticators for group/role accounts when membership to those accounts changes.

## Control guidance

Individual authenticators include, for example, passwords, tokens, biometrics, PKI certificates, and key cards. Initial authenticator content is the actual content (e.g., the initial password) as opposed to requirements about authenticator content (e.g., minimum password length). In many cases, developers ship information system components with factory default authentication credentials to allow for initial installation and configuration. Default authentication credentials are often well known, easily discoverable, and present a significant security risk. The requirement to protect individual authenticators may be implemented via control PL-4 or PS-6 for authenticators in the possession of individuals and by controls AC-3, AC-6, and SC-28 for authenticators stored within organizational information systems (e.g., passwords stored in hashed or encrypted formats, files containing encrypted or hashed passwords accessible with administrator privileges). Information systems support individual authenticator management by organization-defined settings and restrictions for various authenticator characteristics including, for example, minimum password length, password composition, validation time window for time synchronous one-time tokens, and number of allowed rejections during the verification stage of biometric authentication. Specific actions that can be taken to safeguard authenticators include, for example, maintaining possession of individual authenticators, not loaning or sharing individual authenticators with others, and reporting lost, stolen, or compromised authenticators immediately. Authenticator management includes issuing and revoking, when no longer needed, authenticators for temporary access such as that required for remote maintenance. Device authenticators include, for example, certificates and passwords.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

The identity of the individual, group, role, or device is authenticated upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation b.

Any initial authenticator content for authenticators is handled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation c.

Authenticator strength is controlled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation d.

Administrative procedures for authenticator distribution and handling is controlled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation e.

Any change in default content of authenticators is handled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation f.

Lifetime restrictions and reuse conditions for authenticators is handled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation g.

Changing/refreshing of authenticators is handled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation h.

Authenticator content is protected upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation i.

Safeguards for protect authenticators are handled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________

## Implementation j.

Any change of authenticators is handled upstream via Login.gov. The GitLab component uses ia-5 from the main Login.gov SSP.

______________________________________________________________________
