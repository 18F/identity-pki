provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["034795980528"] # require login-tooling-sandbox
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "inspector_alarms" {
  source         = "../../modules/inspector_alarms"
  alarm_name     = "us-west-2-${data.aws_caller_identity.current.account_id}-ecr-alarm"
  sns_target_arn = "arn:aws:sns:us-west-2:${data.aws_caller_identity.current.account_id}:slack-otherevents"
}

data "aws_caller_identity" "current" {}
