---
name: Onboarding Production
about: Give the power of production to a team mate
title: "Onboarding to Production for [insert new team member's name]"
labels: administration
---

# Granting Production Access

Before granting production access:

- The user **must** have a FIPS YubiKey
- The user **must** be using a GFE laptop
- The user **must** have completed mandatory GSA cybersecurity training

## Tasks to be completed by DevOps

- [ ] Edit `terraform/master/global/main.tf` and change the user's group access to the appropriate production enabled group:
      - AppDev: Use `apponcall`
      - DevOps: Use `devops`
      - SecOps: Use `secops`
      - Add _user name_ key and group list to `terraform/master/global/main.tf` and complete `tf-deploy master/global apply`
      - Set initial AWS password and check the box for **Require password reset**
      - Initiate video call
      - Share password via private Google Sheet
- [ ] Complete `tf-deploy master/global apply`

