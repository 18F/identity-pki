#!/bin/bash

# TODO: Automate this and store the token in S3 (or AWS Secrets Manager)
# To generate an API key from a fresh GitLab install for the default admin user:
#
# local> bin/ssm-instance --no-document --newest asg-charlie-gitlab // replace `charlie` with your env.
#
# instance> sudo su -
# instance> gitlab-rails console
#
# irb> user = User.find_by_username('root')
# irb> user.can_create_group = true
# irb> user.save!
# irb> token = user.personal_access_tokens.create(scopes: [:api], name: 'Automation token')
# irb> t = Devise.friendly_token // Remember the output
# irb> token.set_token(t)
# irb> token.save!
# irb> exit
#
# instance> exit
#
# local> export GITLAB_API_TOKEN=OutputFromFriendlyTokenAbove
#
# References:
# - https://docs.gitlab.com/ee/administration/troubleshooting/gitlab_rails_cheat_sheet.html#users
# - https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token-programmatically
#
#
# Token Creation Script in-progress:
#
#object_exists=$(aws s3api head-object --bucket gitlab-charlie-config --key GITLAB_API_TOKEN || true)
#if [ -z "$object_exists" ]; then
#  echo "Generating Gitlab root token"
#  export GITLAB_API_TOKEN=$(echo openssl rand -base64 20 | head -c 20)
#  echo $GITLAB_API_TOKEN | aws s3 cp - s3://$bucket/$key
#  sudo gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api], name: 'Automation token'); token.set_token('$GITLAB_API_TOKEN'); token.save!"
#else
#  echo "Gitlab root token found in S3"
#fi

cd $(dirname $0)

go run sync.go "$@"
