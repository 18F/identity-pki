---
name: Offboarding
about: Track removing credentials for a departing team member
title: "Offboarding for [insert team member's name]"
labels: administration
---

### Remove NAME-OF-PERSON's access from the following services:

_DATE_

Note that not all Login employees will have access to everything listed here.

- [ ] Remove from `user_map` in `terraform/master`
 _user name_

- [ ] SSH
    Remove all SSH keys and groups from the [relevant databag file](https://github.com/18F/identity-devops-private/tree/master/chef/data_bags/users)

- [ ] [Remove New Relic Access](https://account.newrelic.com/accounts/1376370/users)

- [ ] [Remove OpsGenie Access](https://login-gov.app.opsgenie.com/settings/users/)
