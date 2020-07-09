# `identity-devops` | Login.gov Infrastructure

Welcome! This repository is used by the login.gov DevOps team. It contains the infrastructure setup, configuration, automation and monitoring for the `identity-*` repos.

## Need Help? [File Us an Issue!](https://github.com/18F/identity-devops/issues/new/choose)

If you're needing a feature/access/etc. change/update, or want to report a bug, please file us an Issue using the appropriate template. Be sure to follow the [DevOps Issue Acceptance Criteria](https://login-handbook.app.cloud.gov/articles/devops-acceptance-criteria.html) when creating a new issue for us!

All of our outstanding issues are located in the [Login.gov Infrastructure](https://github.com/orgs/18F/projects/5) project board in 18F's GitHub organization. New issues will be added to our **Backlog** to be pulled into subsequent sprints, as per our [Sprint Ceremonies](https://login-handbook.app.cloud.gov/articles/devops-ceremonies.html). If you require an issue to be addressed/resolved during the current sprint, please ping [`@login-devops-oncall` in the `#login-devops` Slack channel](https://gsa-tts.slack.com/archives/C16RSBG49) to discuss.

## Want To Contribute To This Repo?

Pull requests are welcome! If possible, please test out your new code before opening a PR. For the most effective testing, you'll want to have the following configured:

- An AWS IAM user account with `AssumeRole` access to run Terraform commands
- A personal sandbox environment set up properly in AWS
- Your GitHub account has been added to an 18F group with access to open PRs in this repo

Lastly, be sure to follow our [PR Acceptance Criteria](https://login-handbook.app.cloud.gov/articles/devops-acceptance-criteria.html#pull-requests) when opening PRs. If you need assistance with testing your work, please let us know in the PR body.

## Documentation Links

- [Setting Up aws-vault](https://login-handbook.app.cloud.gov/articles/devops-setting-up-aws-vault.html)
- [Personal Sandbox Environment Setup](https://login-handbook.app.cloud.gov/articles/devops-personal-sandbox-env.html)
- [Deploying DevOps Code](https://login-handbook.app.cloud.gov/articles/devops-deploy-devops-code.html)
- [Making Changes via Terraform](https://login-handbook.app.cloud.gov/articles/devops-making-changes-via-terraform.html)

Check the [Login.gov Handbook](https://login-handbook.app.cloud.gov/#devops) for more!
