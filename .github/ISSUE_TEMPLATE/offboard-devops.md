---
name: Offboarding
about: Track removing credentials for a departing team member
title: "Offboarding for [insert team member's name]"
labels: administration
---

### Remove NAME-OF-PERSON's access from the following services:

_DATE_

Note that not all Login employees will have access to everything listed here.

- AWS IAM
  - [ ] Remove from `user_map` in `terraform/master`
   _user name_
  - [ ] Quicksight
  - [ ] Analytics
  - [ ] Master credential

- Internal tools and services
  - [ ] SSH
      Remove all SSH keys and groups from the [relevant databag file](https://github.com/18F/identity-devops-private/tree/master/chef/data_bags/users)

- Github
  - [ ] Remove rights on the [identity teams](https://github.com/orgs/18F/teams/identity-core/members)
     _user name_
  - [ ] Request removal from the 18F org in #admins-github (if leaving TTS/USDS) https://gsa-tts.slack.com/archives/C02KXM98G
  - Note that CircleCI, CodeClimate, and Snyk rights are removed via GitHub integrations

- [ ] [Remove New Relic Access](https://account.newrelic.com/accounts/1376370/users)
- [ ] [Remove OpsGenie Access](https://login-gov.app.opsgenie.com/settings/users/)
