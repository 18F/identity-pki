---
name: AMI Update
about: A PR including new AMIs being rolled out to terraform/app
title: ''
labels: ''
assignees: ''

---

PR_TITLE

<!-- This PR MUST fulfill the accepted criteria defined for DevOps PRs: -->
<!-- https://login-handbook.app.cloud.gov/articles/devops-acceptance-criteria.html -->

<!-- enter data for the new AMIs here -->
<!-- generate: aws ec2 describe-images \
  --owners self \
  --query 'Images[*].{ami:ImageId,date:CreationDate}' \
  --output text | sort -rk 2 | head -n 2 -->
| Account | ID | Date | Description |
| :---: | :---: | :---: | :---: |
| sandbox | ami-XXXXXXXXXXXXXXXXX | <DATE> | base image Ubuntu 18.04 |
| prod | ami-XXXXXXXXXXXXXXXXX | <DATE> | base image Ubuntu 18.04 |
| sandbox | ami-XXXXXXXXXXXXXXXXX | <DATE> | rails image Ubuntu 18.04 |
| prod | ami-XXXXXXXXXXXXXXXXX | <DATE> | rails image Ubuntu 18.04 |
