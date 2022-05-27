---
status:
  - c-implemented
  - c-documented
needs-params:
  - ia-3_prm_2
---

# ia-3 - \[catalog\] Device Identification and Authentication

## Control Statement

The information system uniquely identifies and authenticates organization-defined specific and/or types of devices before establishing a No value found connection.

## Control Objective

Determine if:

- \[1\] the organization defines specific and/or types of devices that the information system uniquely identifies and authenticates before establishing one or more of the following:

  - \[a\] a local connection;
  - \[b\] a remote connection; and/or
  - \[c\] a network connection; and

- \[2\] the information system uniquely identifies and authenticates organization-defined devices before establishing one or more of the following:

  - \[a\] a local connection;
  - \[b\] a remote connection; and/or
  - \[c\] a network connection.

## Control guidance

Organizational devices requiring unique device-to-device identification and authentication may be defined by type, by device, or by a combination of type/device. Information systems typically use either shared known information (e.g., Media Access Control [MAC] or Transmission Control Protocol/Internet Protocol [TCP/IP] addresses) for device identification or organizational authentication solutions (e.g., IEEE 802.1x and Extensible Authentication Protocol [EAP], Radius server with EAP-Transport Layer Security [TLS] authentication, Kerberos) to identify/authenticate devices on local and/or wide area networks. Organizations determine the required strength of authentication mechanisms by the security categories of information systems. Because of the challenges of applying this control on large scale, organizations are encouraged to only apply the control to those limited number (and type) of devices that truly need to support this capability.

______________________________________________________________________

## What is the solution and how is it implemented?

Access to Gitlab is authenticated on a machine-by-machine basis using TCP/IP addresses and AWS security groups to control access to local, remote, and network connections.

______________________________________________________________________
