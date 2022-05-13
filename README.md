# `identity-devops` | Login.gov Infrastructure

Welcome! This repository is used by the login.gov DevOps team. It contains the infrastructure setup, configuration, automation and monitoring for the `identity-*` repos.

## Need Help? [File Us an Issue!](https://github.com/18F/identity-devops/issues/new/choose)

If you're needing a feature/access/etc. change/update, or want to report a bug, please file us an Issue using the appropriate template. Be sure to follow the [DevOps Issue Acceptance Criteria](https://handbook.login.gov/articles/infrastructure-acceptance-criteria.html) when creating a new issue for us!

All of our outstanding issues are located in the [Login.gov Infrastructure](https://github.com/orgs/18F/projects/5) project board in 18F's GitHub organization. New issues will be added to our **Backlog** to be pulled into subsequent sprints, as per our [Sprint Ceremonies](https://handbook.login.gov/articles/infrastructure-ceremonies.html). If you require an issue to be addressed/resolved during the current sprint, please ping [`@login-devops-oncall` in the `#login-devops` Slack channel](https://gsa-tts.slack.com/archives/C16RSBG49) to discuss.

## Want To Contribute To This Repo?

Pull requests are welcome! If possible, please test out your new code before opening a PR. For the most effective testing, you'll want to have the following configured:

- An AWS IAM user account with `AssumeRole` access to run Terraform commands
- A personal sandbox environment set up properly in AWS
- Your GitHub account has been added to an 18F group with access to open PRs in this repo

Lastly, be sure to follow our [PR Acceptance Criteria](https://handbook.login.gov/articles/infrastructure-acceptance-criteria.html#pull-requests) when opening PRs. If you need assistance with testing your work, please let us know in the PR body.

## Documentation Links

- [Setting Up aws-vault](https://github.com/18F/identity-devops/wiki/Setting-Up-AWS-Vault)
- [Personal Sandbox Environment Setup](https://github.com/18F/identity-devops/wiki/Building-a-Personal-Sandbox-Environment)
- [Deploying DevOps Code](https://github.com/18F/identity-devops/wiki/Deploying-Infrastructure-Code)
- [Making Changes via Terraform](https://github.com/18F/identity-devops/wiki/Making-Changes-via-Terraform)
- [Runbook: Infrastructure CI/CD](https://github.com/18F/identity-devops/wiki/Runbook:-Infrastructure-CI-CD)

Check the [Login.gov Handbook](https://handbook.login.gov/#infrastructure) for more!

## Directory Overview

~~~
├── bin                 # Platform CLI utilities
├── cloudlib            # Bespoke Ruby infrastructure CLI library
├── doc
│   ├── adr             # Lightweight Architectural Decision Records
│   ├── architecture    # Architectural diagrams and notes
│   └── compliance      # OSCAL based compliance documentation as code
├── kitchen
│   ├── cookbooks       # Non-public Chef cookbooks (See identity-cookbooks for public)
│   ├── data_bags       # Chef databags (mainly public EIP IP address pools)
│   ├── environments    # Per-application environment Chef settings
│   └── roles           # Chef instance role definitions
└── terraform
    ├── all             # AWS Account common resources
    ├── app             # IdP/PIVCAC/Dashboard application environments
    ├── core            # DNS and other concerns for accounts serving environments
    ├── ecr             # Elastic Container Registry for OCI (Docker) image storage
    ├── gitlab          # GitLab SCM/CI/CD
    ├── imagebuild      # AWS EC2 Image (AMI) build pipelines
    ├── master          # Human account management
    ├── modules         # Shared non-public modules (See identity-terraform for public)
    ├── sms             # PinPoint SMS/Voice resources
    ├── tooling         # Auto-TF infrastructure CD system
    └── waf             # Web Application Firewall - Per-application environment
~~~

