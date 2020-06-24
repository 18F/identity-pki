---
name: Offboarding
about: Track removing credentials for a departing team member
title: "Offboarding for [insert team member's name]"
labels: administration
---

### Remove NAME-OF-PERSON's access from the following services:
_DATE_

Note that not all Login employees will have access to everything listed here.

- TTS
   - [ ] Review and share [leaving GSA/TTS guidance](https://handbook.tts.gsa.gov/leaving-tts/)
   - [ ] Send an email to [all@login.gov](mailto:all@login.gov) announcing that this employee is leaving Login.gov

- AWS IAM
   - [ ] Prod, nonprod AWS accounts
   _user name_
   - [ ] Quicksight
   - [ ] Analytics
   - [ ] Master credential

- Internal mgmt tools and services
   - [ ] SSH
      Remove all SSH keys and groups from the [relevant databag file](https://github.com/18F/identity-devops-private/tree/master/chef/data_bags/users),
      but do not delete it. This allows us to avoid reusing user UIDs.
   - [ ] Kibana
      _user name_
   - [ ] Nessus Server
      _user name_

- Github
   - [ ] Remove rights on the [identity teams](https://github.com/orgs/18F/teams/identity-core/members)
     _user name_
   - [ ] Update [team.yaml](https://github.com/18F/identity-private/blob/master/team/team.yml)! Regenerate [Team.md]() for the wiki
   - [ ] Request removal from the 18F org in #admins-github (if leaving TTS/USDS) https://gsa-tts.slack.com/archives/C02KXM98G
   - Note that CircleCI, CodeClimate, and Snyk rights are removed via GitHub integrations

- Jira
  - [ ] Create a ticket in the Jira AdminTasks project requesting that the user
        be removed from the Login.gov project (and deactivated if they are no
        longer working for GSA).
        https://cm-jira.usa.gov/secure/CreateIssue!default.jspa

- New Relic
   - [ ] https://account.newrelic.com/accounts/1376370/users
     _user name_

- OpsGenie
   - [ ] https://login-gov.app.opsgenie.com/settings/users/
     _user name_

- Statuspage.io
   - [ ] https://manage.statuspage.io/organizations/tg65vnybbdwq/team
     _user name_

- Slack
   - [ ] https://goo.gl/forms/mKATdB9QuNo7AXVY2 -- submit user modification

- [GSA Google Group membership](https://groups.google.com/a/gsa.gov/forum/#!myforums)  @login.gov
   - [ ] Remove from all Groups: all@, identity-devops@, hello@, security@.

- HubSpot
   - [ ] https://app.hubspot.com/settings/5531666/users
     _user name_
