---
name: Onboarding
about: Bring a new team member on board!
title: "Onboarding for [insert new team member's name]"
labels: administration
---

# Onboarding for new team member

_🌮 note: As tasks are completed, please create a separate comment.  This is to show that tasks were completed at a specific time._
_Also, be sure to only copy the sections of this template that are needed for this member's onboarding._

## Tasks for new team member

* [ ] Read through the [wiki](https://github.com/18F/identity-private/wiki)
* [ ] Once you've been added to Slack:
    * [ ] make sure your account is set up [like this](https://handbook.18f.gov/slack/).
    * [ ] make sure to join `#login`, the main announcement channel for our team
* [ ] Make sure your GitHub account is set up [like this](https://handbook.18f.gov/github/#setup).
* [ ] Add the following email address to your Google Calendar to see the Login Services Shared Events calendar: gsa.gov_6ovul6pcsmgd40o8pqn7qmge5g@group.calendar.google.com
* [ ] Add yourself to the [`team.yml`](https://github.com/18F/identity-private/blob/master/team/team.yml) file
* [ ] Request access to relevant Google Groups:
    * All team members: [all@login.gov](https://groups.google.com/a/login.gov/forum/#!forum/all)
    * All federal employees, but not contractors: [login-team@login.gov](https://groups.google.com/a/login.gov/forum/#!forum/login-team)
    * End-User team members: [identity-end-user@login.gov](https://groups.google.com/a/login.gov/forum/#!forum/identity-end-user)
    * Security team members: [security-team@login.gov](https://groups.google.com/a/login.gov/forum/#!forum/security-team)
    * Infra/Devops team members: [identity-devops@login.gov](https://groups.google.com/a/login.gov/forum/#!forum/identity-devops)
    * Anyone interested in agency partner integrations (external inbox): [partners@login.gov](https://groups.google.com/a/login.gov/forum/#!forum/partners)
    * Anyone interested in recruiting federal employees: [jobs@login.gov](https://groups.google.com/a/login.gov/forum/#!forum/jobs)
* [ ] (Optional) [Add your gpg key to github](https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/).

### For new AppDev team members:
* [ ] [Set up your IdP development environment](https://github.com/18F/identity-idp/blob/master/README.md)

### For new DevOps team members:
* [ ] [Set up your personal sandbox environment](https://github.com/18F/identity-private/wiki/Runbook:-Personal-login.gov-DevOps-Environment) (_this is helpful for all new team members!_)

## Tasks for onboarding buddy

* [ ] Give intro to weekly ceremonies and team workflow
* [ ] Request that the new user to be invited to [the 18F org on GitHub](https://github.com/orgs/18F) in #admins-github on Slack.
  * [ ] *For members needing **push commit** access*: Add to the [identity-core](https://github.com/orgs/18F/teams/identity-core/members) team (contact [team maintainers](https://github.com/orgs/18F/teams/identity-core/members?utf8=%E2%9C%93&query=%20role%3Amaintainer) for this)
  * [ ] *For members NOT needing **push** access*: Add to the [identity-team-yml](https://github.com/orgs/18F/teams/identity-team-yml/members) team, which grants read-only access. (contact [team maintainers](https://github.com/orgs/18F/teams/identity-team-yml/members?utf8=%E2%9C%93&query=+role%3Amaintainer) for this)
* [ ] Request Slack access for them in the `#admins-slack` channel and fill out this form: https://goo.gl/forms/4Mz21nvALvITj9Os1.
* [ ] Add them to the [Login Services Shared Events calendar](https://calendar.google.com/calendar/embed?src=gsa.gov_6ovul6pcsmgd40o8pqn7qmge5g%40group.calendar.google.com&ctz=America%2FLos_Angeles).
  * Non-GSA.gov email address: `See all event details` permission
  * With GSA.gov email address: `Make changes AND manage sharing`
* [ ] [Create a JIRA ticket](https://cm-jira.usa.gov/secure/CreateIssue!default.jspa) requesting an account for them
  * Create issue in [the **JIRA AdminTasks** project](https://cm-jira.usa.gov/projects/JAT/issues)
  * List the user's name and email address, and request they be added to the Login.gov project in JIRA
* [ ] Set up pairing session to walk through the relevant project details with the new team member.
  * If you are not the correct person to do the walk-through, please schedule and facilitate a session with the appropriate team member(s).
* [ ] Approve their PR to update [`team.yml`](https://github.com/18F/identity-private/blob/master/team/team.yml) with their info
  * [ ] Regenerate [`Team.md`](https://github.com/18F/identity-private/wiki/Team) for the wiki
* [ ] Verify their membership in all appropriate Google Groups, especially all@login.gov. This will grant them permission to see the Login.gov Team Drive and other Google Docs.

### For new end-user team members:
* [ ] Invite the new team member to the following events:
  * end-user sprint planning (every other Monday)
  * end-user mid-sprint check-in (alternate Mondays)
  * login.gov demo (every other Friday)
  * end-user sprint retro (every other Friday)

## Tasks to be completed by DevOps

### For all new Developers and DevOps team members:
* [ ] Complete [GSA OLU](https://insite.gsa.gov/topics/training-and-development/online-university-olu?term=olu) IT Security Awareness Training, including accepting the GSA IT Rules of Behavior, which is required before we can give you access to any login.gov systems. If you joined GSA more than two months ago, you’ve already completed this task and can just check the box. (Detailees must complete similar organization driven training and provide as proof to login.gov team members)
* [ ] Add the new team member to [New Relic](https://account.newrelic.com/accounts/1376370/users/new)
* [ ] Invite the new team member to [Opsgenie](https://login-gov.app.opsgenie.com/settings/users/)
