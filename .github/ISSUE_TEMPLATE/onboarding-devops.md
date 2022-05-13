---
name: Onboarding New Team Member
about: Bring a new team member on board!
title: "Onboarding for [TEAM_MEMBER]"
labels: administration
assignees: ''

---

<!-- Not all items below will be applicable to every team-member. -->
<!-- Please remove any items that don't apply before submitting this issue. -->

# Tasks (To Be Completed by Onboarding Buddy)

***NOTE:*** As much as is possible, please create a separate comment when completing
each of the tasks below. This is to show that each task was completed at a specific time.

- [ ] For AppDev, DevOps, SecOps, or other members requiring AWS access:
  - [ ] Use `bin/manage-user` to add the team member to `terraform/master/global/users.yaml`
      and include them as a member of the appropriate AWS group(s):
    - [ ] AppDev: `appdev` group
    - [ ] DevOps/SRE: `devopsnonprod` group
    - [ ] SecOps: `secopsnonprod` group
    - [ ] Add `ec2_username` if team member needs console/SSM access to EC2 hosts
    - [ ] Add `gitlab_groups` / `git_username` if team member needs GitLab access
  - [ ] Open a PR with the above change(s)
    - [ ] Upon approval, merge PR and create AWS user account
        via `tf-deploy master/global apply`
  - [ ] Use `bin/create-aws-creds` to create/apply a temporary password,
      AWS Access Key ID and AWS Secret Access Key
  - [ ] Set up a video call in Google Meet for identity verification
  - [ ] Share password via gChat messaging
- [ ] For non-DevOps team members:
  - [ ] Create [personal Terraform/Chef config files](https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#personal-configs) in `identity-devops` and `identity-devops-private`,
        using `ec2_username` above for the environment name
  - [ ] Build personal sandbox development environment using `bin/create-sandbox ENV_NAME`
  - [ ] Add an `env-ENV_NAME` line to each JSON file in `chef/data_bags/users` used by a DevOps/SecOps member with production access
- [ ] Add to [New Relic](https://account.newrelic.com/accounts/1376370/users/new) (AppDev, DevOps, and SecOps members)
- [ ] Invite to [Opsgenie](https://login-gov.app.opsgenie.com/settings/users/) (on-call AppDev, DevOps, and SecOps members)

<!-- REMOVE ALL COMMENT BLOCKS, LIKE THIS ONE, BEFORE SUBMITTING! -->
