---
name: Onboarding Production
about: Give the power of production to a team member
title: "Onboarding to Production for [TEAM_MEMBER]"
labels: administration
assignees: ''

---

### Before granting production access, [TEAM_MEMBER] ***must***:

- [ ] Have a FIPS YubiKey
- [ ] Be using a GFE laptop
- [ ] Have completed mandatory GSA Cybersecurity Training

<!-- Not all items below will be applicable to every team-member. -->
<!-- Please remove any items that don't apply before submitting this issue. -->

# Tasks (To Be Completed by Platform Team)

- [ ] Use `bin/manage-user` to add the team member to `terraform/master/global/users.yaml`
    and include them as a member of the appropriate AWS group(s):
  - [ ] AppDev: `apponcall` group
  - [ ] DevOps/SRE: `devops` group
  - [ ] SecOps: `secops` group
  - [ ] Confirm `ec2_username` if team member needs console/SSM access to EC2 hosts
  - [ ] Confirm `gitlab_groups` / `git_username` if team member needs GitLab access
- [ ] Open a PR with the above change(s)
  - [ ] Upon approval, merge PR and create AWS user account
        via `tf-deploy master/global apply`

<!-- REMOVE ALL COMMENT BLOCKS, LIKE THIS ONE, BEFORE SUBMITTING! -->
