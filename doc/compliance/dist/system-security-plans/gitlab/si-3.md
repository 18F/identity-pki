---
status:
  - c-not-implemented
  - c-not-documented
needs-params:
  - si-3_prm_2
  - si-3_prm_3
---

# si-3 - \[catalog\] Malicious Code Protection

## Control Statement

The organization:

- \[a\] Employs malicious code protection mechanisms at information system entry and exit points to detect and eradicate malicious code;

- \[b\] Updates malicious code protection mechanisms whenever new releases are available in accordance with organizational configuration management policy and procedures;

- \[c\] Configures malicious code protection mechanisms to:

  - \[1\] Perform periodic scans of the information system organization-defined frequency and real-time scans of files from external sources at No value found as the files are downloaded, opened, or executed in accordance with organizational security policy; and
  - \[2\]  No value found in response to malicious code detection; and

- \[d\] Addresses the receipt of false positives during malicious code detection and eradication and the resulting potential impact on the availability of the information system.

## Control Objective

Determine if the organization:

- \[a_obj\] employs malicious code protection mechanisms to detect and eradicate malicious code at information system:

  - \[1\] entry points;
  - \[2\] exit points;

- \[b_obj\] updates malicious code protection mechanisms whenever new releases are available in accordance with organizational configuration management policy and procedures (as identified in CM-1);

- \[c_obj\]

  - \[1\] defines a frequency for malicious code protection mechanisms to perform periodic scans of the information system;
  - \[2\] defines action to be initiated by malicious protection mechanisms in response to malicious code detection;
  - \[3\]

    - \[3\] configures malicious code protection mechanisms to:

      - \[a\] perform periodic scans of the information system with the organization-defined frequency;
      - \[b\] perform real-time scans of files from external sources at endpoint and/or network entry/exit points as the files are downloaded, opened, or executed in accordance with organizational security policy;

    - \[3\] configures malicious code protection mechanisms to do one or more of the following:

      - \[a\] block malicious code in response to malicious code detection;
      - \[b\] quarantine malicious code in response to malicious code detection;
      - \[c\] send alert to administrator in response to malicious code detection; and/or
      - \[d\] initiate organization-defined action in response to malicious code detection;

- \[d_obj\]

  - \[1\] addresses the receipt of false positives during malicious code detection and eradication; and
  - \[2\] addresses the resulting potential impact on the availability of the information system.

## Control guidance

Information system entry and exit points include, for example, firewalls, electronic mail servers, web servers, proxy servers, remote-access servers, workstations, notebook computers, and mobile devices. Malicious code includes, for example, viruses, worms, Trojan horses, and spyware. Malicious code can also be encoded in various formats (e.g., UUENCODE, Unicode), contained within compressed or hidden files, or hidden in files using steganography. Malicious code can be transported by different means including, for example, web accesses, electronic mail, electronic mail attachments, and portable storage devices. Malicious code insertions occur through the exploitation of information system vulnerabilities. Malicious code protection mechanisms include, for example, anti-virus signature definitions and reputation-based technologies. A variety of technologies and methods exist to limit or eliminate the effects of malicious code. Pervasive configuration management and comprehensive software integrity controls may be effective in preventing execution of unauthorized code. In addition to commercial off-the-shelf software, malicious code may also be present in custom-built software. This could include, for example, logic bombs, back doors, and other types of cyber attacks that could affect organizational missions/business functions. Traditional malicious code protection mechanisms cannot always detect such code. In these situations, organizations rely instead on other safeguards including, for example, secure coding practices, configuration management and control, trusted procurement processes, and monitoring practices to help ensure that software does not perform functions other than the functions intended. Organizations may determine that in response to the detection of malicious code, different actions may be warranted. For example, organizations can define actions in response to malicious code detection during periodic scans, actions in response to detection of malicious downloads, and/or actions in response to detection of maliciousness when attempting to open or execute files.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

Add control implementation description here for item si-3_smt.a

______________________________________________________________________

## Implementation b.

Add control implementation description here for item si-3_smt.b

______________________________________________________________________

## Implementation c.

Add control implementation description here for item si-3_smt.c

______________________________________________________________________

## Implementation d.

Add control implementation description here for item si-3_smt.d

______________________________________________________________________
