---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp
---

# ra-5 - \[catalog\] Vulnerability Scanning

## Control Statement

The organization:

- \[a\] Scans for vulnerabilities in the information system and hosted applications organization-defined frequency and/or randomly in accordance with organization-defined process and when new vulnerabilities potentially affecting the system/applications are identified and reported;

- \[b\] Employs vulnerability scanning tools and techniques that facilitate interoperability among tools and automate parts of the vulnerability management process by using standards for:

  - \[1\] Enumerating platforms, software flaws, and improper configurations;
  - \[2\] Formatting checklists and test procedures; and
  - \[3\] Measuring vulnerability impact;

- \[c\] Analyzes vulnerability scan reports and results from security control assessments;

- \[d\] Remediates legitimate vulnerabilities organization-defined response times in accordance with an organizational assessment of risk; and

- \[e\] Shares information obtained from the vulnerability scanning process and security control assessments with organization-defined personnel or roles to help eliminate similar vulnerabilities in other information systems (i.e., systemic weaknesses or deficiencies).

## Control Objective

Determine if the organization:

- \[a_obj\]

  - \[1\]

    - \[a\] defines the frequency for conducting vulnerability scans on the information system and hosted applications; and/or
    - \[b\] defines the process for conducting random vulnerability scans on the information system and hosted applications;

  - \[2\] in accordance with the organization-defined frequency and/or organization-defined process for conducting random scans, scans for vulnerabilities in:

    - \[a\] the information system;
    - \[b\] hosted applications;

  - \[3\] when new vulnerabilities potentially affecting the system/applications are identified and reported, scans for vulnerabilities in:

    - \[a\] the information system;
    - \[b\] hosted applications;

- \[b_obj\] employs vulnerability scanning tools and techniques that facilitate interoperability among tools and automate parts of the vulnerability management process by using standards for:

  - \[1_obj\]

    - \[1\] enumerating platforms;
    - \[2\] enumerating software flaws;
    - \[3\] enumerating improper configurations;

  - \[2_obj\]

    - \[1\] formatting checklists;
    - \[2\] formatting test procedures;

  - \[3_obj\] measuring vulnerability impact;

- \[c_obj\]

  - \[1\] analyzes vulnerability scan reports;
  - \[2\] analyzes results from security control assessments;

- \[d_obj\]

  - \[1\] defines response times to remediate legitimate vulnerabilities in accordance with an organizational assessment of risk;
  - \[2\] remediates legitimate vulnerabilities within the organization-defined response times in accordance with an organizational assessment of risk;

- \[e_obj\]

  - \[1\] defines personnel or roles with whom information obtained from the vulnerability scanning process and security control assessments is to be shared;
  - \[2\] shares information obtained from the vulnerability scanning process with organization-defined personnel or roles to help eliminate similar vulnerabilities in other information systems (i.e., systemic weaknesses or deficiencies); and
  - \[3\] shares information obtained from security control assessments with organization-defined personnel or roles to help eliminate similar vulnerabilities in other information systems (i.e., systemic weaknesses or deficiencies).

## Control guidance

Security categorization of information systems guides the frequency and comprehensiveness of vulnerability scans. Organizations determine the required vulnerability scanning for all information system components, ensuring that potential sources of vulnerabilities such as networked printers, scanners, and copiers are not overlooked. Vulnerability analyses for custom software applications may require additional approaches such as static analysis, dynamic analysis, binary analysis, or a hybrid of the three approaches. Organizations can employ these analysis approaches in a variety of tools (e.g., web-based application scanners, static analysis tools, binary analyzers) and in source code reviews. Vulnerability scanning includes, for example: (i) scanning for patch levels; (ii) scanning for functions, ports, protocols, and services that should not be accessible to users or devices; and (iii) scanning for improperly configured or incorrectly operating information flow control mechanisms. Organizations consider using tools that express vulnerabilities in the Common Vulnerabilities and Exposures (CVE) naming convention and that use the Open Vulnerability Assessment Language (OVAL) to determine/test for the presence of vulnerabilities. Suggested sources for vulnerability information include the Common Weakness Enumeration (CWE) listing and the National Vulnerability Database (NVD). In addition, security control assessments such as red team exercises provide other sources of potential vulnerabilities for which to scan. Organizations also consider using tools that express vulnerability impact by the Common Vulnerability Scoring System (CVSS).

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

The Gitlab component aligns with RA-5, part A from the main Login.gov SSP.

______________________________________________________________________

## Implementation b.

The Gitlab component aligns with RA-5, part B from the main Login.gov SSP.

______________________________________________________________________

## Implementation c.

The Gitlab component aligns with RA-5, part C from the main Login.gov SSP.

______________________________________________________________________

## Implementation d.

The Gitlab component aligns with RA-5, part D from the main Login.gov SSP.

______________________________________________________________________

## Implementation e.

The Gitlab component follows aligns with RA-5, part E from the main Login.gov SSP.

______________________________________________________________________
