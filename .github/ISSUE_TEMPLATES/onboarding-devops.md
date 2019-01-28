---
title: 'Onboarding for [insert new team member's name]'
labels: administration
---

# Onboarding for new team member

## Tasks for new team member

* [ ] Read through the [wiki](https://github.com/18F/identity-private/wiki)
* [ ] Make sure your GitHub account is set up [like this](https://handbook.18f.gov/github/#setup).
* [ ] Once you've been added to Slack:
    * [ ] make sure your account is set up [like this](https://handbook.18f.gov/slack/).
    * [ ] make sure to join `#login`, the main announcement channel for our team
* [ ] Add the following email address to your Google Calendar to see the Login Services Shared Events calendar: gsa.gov_6ovul6pcsmgd40o8pqn7qmge5g@group.calendar.google.com
* [ ] [Set up your development environment](https://github.com/18F/identity-idp/blob/master/README.md) (_this is helpful for all new team members!_)
* [ ] Add yourself to the [team page](https://github.com/18F/identity-private/wiki/Team).
* [ ] Request access to the listserv (all@login.gov): * [ ] Request access to the listserv (all@login.gov): https://groups.google.com/a/login.gov/forum/#!forum/all

## Tasks for on-boarding buddy 

* [ ] Give intro to weekly ceremonies and team workflow
* [ ] Ask the new team member for their GitHub username. Make a request to the [team owner](https://github.com/orgs/18F/teams/identity?utf8=%E2%9C%93&query=%20role%3Aowner) or a [team maintainer](https://github.com/orgs/18F/teams/identity?utf8=%E2%9C%93&query=%20role%3Amaintainer) to add the username to the `identity` GitHub team.
    * [ ] For 18F, you may need access to `identity-core`.
* [ ] If the new team member does not have Slack access, request access for them in the `#admins-slack` channel and fill out this form: https://goo.gl/forms/4Mz21nvALvITj9Os1.
* [ ] Add the new team member to the Login Services Shared Events calendar. Add users with non-GSA.gov email addresses with the `See all event details` permission, and those with GSA.gov emails as `Make changes AND manage sharing`.
* [ ] Set up pairing session to walk through the relevant project details with the new team member. If you are not the correct person to do the walk-through, please schedule and facilitate a session with the appropriate team member(s).

### For new end-user team members:
* [ ] Invite the new team member to the following events:
  * end-user sprint planning (every other Monday)
  * end-user mid-sprint check-in (alternate Mondays)
  * login.gov demo (every other Friday)
  * end-user sprint retro (every other Friday)
* [ ] For access to environments, extract PIV public key following these steps: https://github.com/18F/identity-private/wiki/Operations:-MacOSX-PIV-to-SSH-key-extraction, and securely pass it to a member of the devops team.
* [ ] For access to Kibana log searches, create a password hash and get it to a member of the devops team securely (`htpasswd -nB -C 10 username > /tmp/usernamehash ; gpg -a --encrypt -r yourgpgkeyid < /tmp/usernamehash`, for example).  

## Tasks to be completed by DevOps

### For all new Developers and DevOps team members:

* [ ] Complete [GSA OLU](https://insite.gsa.gov/topics/training-and-development/online-university-olu?term=olu) IT Security Awareness Training, including accepting the GSA IT Rules of Behavior, which is required before we can give you access to any login.gov systems. If you joined GSA more than two months ago, you’ve already completed this task and can just check the box. (Detailees must complete similar organization driven training and provide as proof to login.gov team members)
* [ ] Obtain the PIV public key from the new member, create a file under https://github.com/18F/identity-devops-private/tree/master/chef/data_bags/users that has the PIV key in it and all the environments they need access to.
* [ ] Add password sent securely by new user to the `common/elk_htpasswd.json` file in the secrets bucket.  This will allow access to Kibana for log searches.
* [ ] Relaunch ASG systems (jumphosts, idp, pivcac) to ensure that the user is in there.
* [ ] Add the new team member to New Relic
* [ ] Configure access for new team member to
  * [ ] dev
  * [ ] qa 

### For new DevOps team members only:
* [ ] Configure access for the new team member to
  * [ ] dm (data migration)  
  * [ ] staging/pre-prod (staging)  
  * [ ] prod (prod)
  * [ ] Add the new team member to [AWS 18f-identity-analytics](https://18f-identity-analytics.signin.aws.amazon.com/console) account to IAM group `identity-power` or `identity-admin`
  * [ ] Add the new team member to [AWS 18f-identity](https://18f-identity-dev.signin.aws.amazon.com/console) account to IAM group `identity-admin`
  * [ ] Add the new team member to [AWS 18f-identity](https://18f-identity.signin.aws.amazon.com/console) account to IAM group `identity-power`
* [ ] Add the new team member to DevOps LG infrastructure (Jumphost, ELK, outbound proxy)
* [ ] Add the new team member to PagerDuty:  do this through https://github.com/18F/Infrastructure/issues/new, where you request to the infrastructure team that a new user be created and added to the login.gov team.
* [ ] Ask the new team member to create a GSA-dedicated [SSLMate account](https://sslmate.com/signup) and subscribe to updates on `login.gov` and `identitysandbox.gov`.

### For new Analytics team members only:
* [ ] Add the new team member to [AWS 18f-identity-analytics](https://18f-identity-analytics.signin.aws.amazon.com/console) account to IAM group `identity-power`
* [ ] Add the new team member to [AWS 18f-identity](https://18f-identity-dev.signin.aws.amazon.com/console) account to IAM group `identity-redshift`
* [ ] Add the new team member to [AWS 18f-identity](https://18f-identity.signin.aws.amazon.com/console) account to IAM group `identity-redshift`
* [ ] Add the new team member to `prod` Jumphost as none sudoer access for redshift sql cli


### For those requiring additional access:
* [ ] Configure access for the new team member to
  * [ ] performance testing (pt)  
  * [ ] integration (int)
* [ ] Twilio
* [ ] Opsgenie
* [ ] Quicksite
* [ ] Nessus Scanner
* [ ] LexisNexis RDP Reporting Portal