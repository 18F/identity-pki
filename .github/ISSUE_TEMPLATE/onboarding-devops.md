---
name: Onboarding
about: Bring a new team member on board!
title: "Onboarding for [insert new team member's name]"
labels: administration
---

# Onboarding for new team member

- As tasks are completed, please create a separate comment.  This is to show that tasks were completed at a specific time.
- Also, please note that not all items below will be applicable to every team-member, you can remove items that don't apply.

## Tasks to be completed by DevOps

- [ ] For AppDev, DevOps, SecOps, or other users requiring AWS access:
      - Add _user name_ key and group list to `terraform/master/global/main.tf` and complete `tf-deploy master/global apply`
      - Set initial AWS password and check the box for **Require password reset**
      - Initiate video call
      - Share password via private Google Sheet
- [ ] For AppDev, DevOps, and SecOps members add the new team member to [New Relic](https://account.newrelic.com/accounts/1376370/users/new)
- [ ] For on-call AppDev, DevOps, and SecOps members invite the new team member to [Opsgenie](https://login-gov.app.opsgenie.com/settings/users/)
