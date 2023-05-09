---
status:
  - c-implemented
  - c-documented
  - c-in-parent-ssp

---

# cm-5.3 - \[catalog\] Signed Components

## Control Statement

The information system prevents the installation of organization-defined software and firmware components without verification that the component has been digitally signed using a certificate that is recognized and approved by the organization.

## Control Objective

Determine if:

- \[1\] the organization defines software and firmware components that the information system will prevent from being installed without verification that such components have been digitally signed using a certificate that is recognized and approved by the organization; and

- \[2\] the information system prevents the installation of organization-defined software and firmware components without verification that such components have been digitally signed using a certificate that is recognized and approved by the organization.

## Control guidance

Software and firmware components prevented from installation unless signed with recognized and approved certificates include, for example, software and firmware version updates, patches, service packs, device drivers, and basic input output system (BIOS) updates. Organizations can identify applicable software and firmware components by type, by specific items, or a combination of both. Digital signatures and organizational verification of such signatures, is a method of code authentication.

______________________________________________________________________

## What is the solution and how is it implemented?

The GitLab component aligns with CM-5(3) – Infrastructure Components, from the main Login.gov SSP. 

GitLab packages are signed by GitLab, and verified with a public key.

Our Container Development<sup>1</sup> wiki page tells us to use Docker Content Trust, where possible.

<sup>1</sup> https://github.com/18F/identity-devops/wiki/Container-Development

______________________________________________________________________
