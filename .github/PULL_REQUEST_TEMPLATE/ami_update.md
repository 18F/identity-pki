---
name: AMI Update
about: A PR including new AMIs being rolled out to terraform/app
title: "AMI update, YYYY-MM-DD"
labels: ''
assignees: ''

---

<!-- This PR MUST fulfill the accepted criteria defined for DevOps PRs: -->
<!-- https://handbook.login.gov/articles/platform-acceptance-criteria.html#pull-requests -->

<!-- generate AMI data: bin/get-images -l -->
<!-- and replace the below block with the generated data -->

| Account | ID | Date | Description |
| :---: | :---: | :---: | :---: |
| sandbox | ami-XXXXXXXXXXXXXXXXX | <DATE> | base image Ubuntu 18.04 |
| prod | ami-XXXXXXXXXXXXXXXXX | <DATE> | base image Ubuntu 18.04 |
| sandbox | ami-XXXXXXXXXXXXXXXXX | <DATE> | rails image Ubuntu 18.04 |
| prod | ami-XXXXXXXXXXXXXXXXX | <DATE> | rails image Ubuntu 18.04 |

<!-- REMOVE ALL COMMENT BLOCKS, LIKE THIS ONE, BEFORE SUBMITTING! -->
