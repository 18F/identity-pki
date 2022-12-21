---
name: Offboarding
about: Track removing credentials for a departing team member
title: "Offboarding for [TEAM_MEMBER]"
labels: administration
assignees: ''

---

#### Due Date: _DATE_

<!-- Not all items below will be applicable to every team-member. -->
<!-- Please remove any items that don't apply before submitting this issue. -->

### Remove [TEAM_MEMBER]'s access from the following services:

***NOTE:*** As much as is possible, please create a separate comment when completing
each of the tasks below. This is to show that each task was completed at a specific time.

- [ ] AWS
  - [ ] Disable password authentication for the team member's AWS account
  - [ ] Disable / Delete Access Key ID(s) and Secret Access Key(s)
  - [ ] Spin down personal sandbox environment using `bin/destroy-sandbox ENV_NAME`
- [ ] `identity-devops`
  - [ ] Use `bin/manage-user` to remove from `terraform/master/global/users.yaml`
  - [ ] Remove [personal Chef environment file (`ENV.json`)](https://github.com/18F/identity-devops/tree/main/kitchen/environments)
  - [ ] Remove [personal `waf` environment directory](https://github.com/18F/identity-devops/tree/main/terraform/waf) (if one exists)
    - [ ] Spin down using `bin/tf-deploy waf/ENV_NAME destroy`
    - [ ] Remove directory and contents from `terraform/waf/`
  - [ ] Open a PR with the above change(s)
    - [ ] Upon approval, merge PR and delete AWS user account
        via `tf-deploy master/global apply`
- [ ] `identity-devops-private`
  - [ ] AFTER spinning down sandbox environment, open a PR removing the following files:
    - [ ] `chef/data_bags/users` JSON file
    - [ ] `chef/environments` JSON file
    - [ ] `env` .sh file
    - [ ] `vars/` .tfvars file
    - [ ] Remove `env-USERNAME` line from any other `data_bags/users` JSON files

    ***NOTE:*** From the top level of `identity-devops-private`, run the following commands
    to perform the above tasks (replacing `USERNAME` appropriately):
    ```
    find . -name "USERNAME*" -delete
    find . -type f ! -path "*.git*" | xargs sed -i '' -E '/USERNAME/d'
    ```
  - [ ] Merge PR upon approval
- [ ] Remove from New Relic [via the Users page](https://account.newrelic.com/accounts/1376370/users)
- [ ] Remove from OpsGenie [via the Users page](https://login-gov.app.opsgenie.com/settings/users/)

<!-- REMOVE ALL COMMENT BLOCKS, LIKE THIS ONE, BEFORE SUBMITTING! -->
