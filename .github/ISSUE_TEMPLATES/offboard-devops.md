---
title: 'Offboard  for [insert team member's name]'
labels: administration
---

### Remove NAME-OF-PERSON's access from the following services:
_DATE_

- AWS
   - [ ] Prod, nonprod AWS accounts  
   _user name_  
   - [ ] AWS Quicksight
   - [ ] AWS Analytics

- Internal mgmt tools and services
   - [ ] SSH
      Remove all SSH keys and groups from the [relevant databag file](https://github.com/18F/identity-devops-private/tree/master/chef/data_bags/users),
      but do not delete it. This allows us to avoid reusing user UIDs.
   - [ ] Kibana  
      _user name_  
   - [ ] Nessus Server  
      _user name_ 

- Proofers/Partners  
   - [ ] Equifax  
     _user name_ 
   - [ ] AAMVA  
      _user name_  

- Github
   - [ ] Remove rights on the [identity teams](https://github.com/orgs/18F/teams/identity-core/members)  
     _user name_ 
   - [ ] Update [team.yaml](https://github.com/18F/identity-private/blob/master/team/team.yml)! Regenerate [Team.md]() for the wiki
   - [ ] Request removal from the 18F org in #admins-github (if leaving 18f/USDS)  

- Github integrations
   - [ ] CircleCi
   - [ ] CodeClimate
   - [ ] Snyk
        
- [ ] Twilio
   - [ ] https://www.twilio.com/console/project/users  
     _user name_ 
   - [ ] The devops@gsa.gov google group is the account owner
   
- [ ] New Relic
   - [ ] https://account.newrelic.com/accounts/1376370/users  
     _user name_ 
   
- [ ] OpsGenie
   - [ ] 
      
- Slack
   - [ ] https://goo.gl/forms/mKATdB9QuNo7AXVY2 -- submit user modification
   
- GSA Google Group membership  @login.gov  
   - [ ] Remove from identity-devops@, hello@, security@.


#### Final Step
- GSA Account
   - [ ] GSA offboarding
