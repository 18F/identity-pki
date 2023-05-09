---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp

---

# cm-6 - \[catalog\] Configuration Settings

## Control Statement

The organization:

- \[a\] Establishes and documents configuration settings for information technology products employed within the information system using organization-defined security configuration checklists that reflect the most restrictive mode consistent with operational requirements;

- \[b\] Implements the configuration settings;

- \[c\] Identifies, documents, and approves any deviations from established configuration settings for organization-defined information system components based on organization-defined operational requirements; and

- \[d\] Monitors and controls changes to the configuration settings in accordance with organizational policies and procedures.

## Control Objective

Determine if the organization:

- \[a_obj\]

  - \[1\] defines security configuration checklists to be used to establish and document configuration settings for the information technology products employed;
  - \[2\] ensures the defined security configuration checklists reflect the most restrictive mode consistent with operational requirements;
  - \[3\] establishes and documents configuration settings for information technology products employed within the information system using organization-defined security configuration checklists;

- \[b_obj\] implements the configuration settings established/documented in CM-6(a);;

- \[c_obj\]

  - \[1\] defines information system components for which any deviations from established configuration settings must be:

    - \[a\] identified;
    - \[b\] documented;
    - \[c\] approved;

  - \[2\] defines operational requirements to support:

    - \[a\] the identification of any deviations from established configuration settings;
    - \[b\] the documentation of any deviations from established configuration settings;
    - \[c\] the approval of any deviations from established configuration settings;

  - \[3\] identifies any deviations from established configuration settings for organization-defined information system components based on organizational-defined operational requirements;
  - \[4\] documents any deviations from established configuration settings for organization-defined information system components based on organizational-defined operational requirements;
  - \[5\] approves any deviations from established configuration settings for organization-defined information system components based on organizational-defined operational requirements;

- \[d_obj\]

  - \[1\] monitors changes to the configuration settings in accordance with organizational policies and procedures; and
  - \[2\] controls changes to the configuration settings in accordance with organizational policies and procedures.

## Control guidance

Configuration settings are the set of parameters that can be changed in hardware, software, or firmware components of the information system that affect the security posture and/or functionality of the system. Information technology products for which security-related configuration settings can be defined include, for example, mainframe computers, servers (e.g., database, electronic mail, authentication, web, proxy, file, domain name), workstations, input/output devices (e.g., scanners, copiers, and printers), network components (e.g., firewalls, routers, gateways, voice and data switches, wireless access points, network appliances, sensors), operating systems, middleware, and applications. Security-related parameters are those parameters impacting the security state of information systems including the parameters required to satisfy other security control requirements. Security-related parameters include, for example: (i) registry settings; (ii) account, file, directory permission settings; and (iii) settings for functions, ports, protocols, services, and remote connections. Organizations establish organization-wide configuration settings and subsequently derive specific settings for information systems. The established settings become part of the systems configuration baseline. Common secure configurations (also referred to as security configuration checklists, lockdown and hardening guides, security reference guides, security technical implementation guides) provide recognized, standardized, and established benchmarks that stipulate secure configuration settings for specific information technology platforms/products and instructions for configuring those information system components to meet operational requirements. Common secure configurations can be developed by a variety of organizations including, for example, information technology product developers, manufacturers, vendors, consortia, academia, industry, federal agencies, and other organizations in the public and private sectors. Common secure configurations include the United States Government Configuration Baseline (USGCB) which affects the implementation of CM-6 and other controls such as AC-19 and CM-7. The Security Content Automation Protocol (SCAP) and the defined standards within the protocol (e.g., Common Configuration Enumeration) provide an effective method to uniquely identify, track, and control configuration settings. OMB establishes federal policy on configuration requirements for federal information systems.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

The GitLab component aligns with CM-6, part A from the main Login.gov SSP.

Also, our Container Development<sup>1</sup> wiki page gives us recommendations from the docker CIS benchmark for us to follow to create secure and minimal images.

<sup>1</sup> https://github.com/18F/identity-devops/wiki/Container-Development

______________________________________________________________________

## Implementation b.

The GitLab component aligns with CM-6, part B from the main Login.gov SSP.

As much as possible, we have implemented the checklist items in CM-6, Part A.

______________________________________________________________________

## Implementation c.

The GitLab component aligns with CM-6, part C from the main Login.gov SSP.

______________________________________________________________________

## Implementation d.

The GitLab component aligns with CM-6, part D from the main Login.gov SSP.

______________________________________________________________________
