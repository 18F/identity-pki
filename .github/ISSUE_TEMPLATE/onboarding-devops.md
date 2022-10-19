---
name: Onboarding New Team Member
about: Bring a new team member on board!
title: "Onboarding for [TEAM_MEMBER]"
labels: administration
assignees: ''

---
# New User Information

<!-- HEY, YOU!  Yeah.. the one filling this out!  Put a X in the box for
     the type of user you are requesting access for.  Just type out more
     info after "Other:" below if they don't match one of these categories! -->

User is a new: (Please check one or explain in Other)
* [ ] Application / Product Engineer
* [ ] Platform / DevOps Engineer / SRE
* [ ] Security Engineer / DevSecOps Engineer
* [ ] Product Manager or ScrumMaster
* [ ] Specialist: Fraud Analytics
* [ ] Specialist: Operations/Finance
* [ ] Other:

<!-- It's me again!  You are almost done.

     Click "Projects" on the right then click the "Repository" tab and click "LG Platform - Interrupts".
     This will put it on the interrupts board where we track this work.

     Now click "Submit new issue" and the DevOps Oncall engineer will take care of the rest! -->

# Tasks to be completed by DevOps Oncall

***NOTE:*** As much as is possible, please create a separate comment when completing
each of the tasks below. This is to show that each task was completed at a specific time.

Reference [Runbook:-Onboarding-and-Offboarding-AWS-and-GitLab-Users#functional-roles-and-groups](https://github.com/18F/identity-devops/wiki/Runbook:-Onboarding-and-Offboarding-AWS-and-GitLab-Users#functional-roles-and-groups)
to idenify the proper Pre-Prod AWS group(s), GitLab group(s), and NewRelic access
the user should have.

- [ ] Use `bin/manage-user` to add the team member to `terraform/master/global/users.yaml`
    - Add AWS group(s)
    - Add `ec2_username` if team member needs console/SSM access to EC2 hosts
    - Add `gitlab_groups` if team member needs GitLab access
~~~sh
# Example - Add a user with the AWS name "steamboat.willie" and EC2 username of
#           "swillie" to the "appdev" group in AWS and the "appdev" group in GitLab
bin/manage-user -u steamboat.willie -e swillie -a appdev -g appdev
~~~
  - [ ] Open a PR with the above change(s)
    - [ ] Upon approval, merge PR and create AWS user account
        via `tf-deploy master/global apply`
  - [ ] Use `bin/create-aws-creds` to create/apply a temporary password,
      AWS Access Key ID and AWS Secret Access Key
  - [ ] Set up a video call in Google Meet for identity verification
  - [ ] Share password via gChat messaging
- [ ] For anyone requiring shell access:
  - [ ] Create and merge a PR to add a Chef databag file using `ec2_username` in https://github.com/18F/identity-devops-private/tree/main/chef/data_bags/users
- [ ] If needed, add to [New Relic](https://account.newrelic.com/accounts/1376370/users/new)
