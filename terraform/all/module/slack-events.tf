# TODO: use for_each to create resources AND modules
# once we move to Terraform 0.13

resource "aws_sns_topic" "slack_events" {
  name = "slack-events"
}

module "slack_default_login_events" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=a5e12e94d6038477782a370395702aa7f250562c"
  #source = "../../../identity-terraform/launch_template"
  
  lambda_name = lookup(local.slack_alerts["slack_default"], "lambda_name")
  lambda_description = lookup(local.slack_alerts["slack_default"], "lambda_description")
  slack_webhook = var.slack_webhook
  slack_channel = "login-events"
  slack_username = "Login.gov"
  slack_icon = 
  sns_topic = var.slack_sns_topics
}

resource "aws_sns_topic" "slack_otherevents" {
  name = "slack-otherevents"
}

module "slack_default_login_otherevents" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=a5e12e94d6038477782a370395702aa7f250562c"
  #source = "../../../identity-terraform/launch_template"
  
  lambda_name = lookup(local.slack_alerts["slack_default"], "lambda_name")
  lambda_description = lookup(local.slack_alerts["slack_default"], "lambda_description")
  slack_webhook = var.slack_webhook
  slack_channel = "login-otherevents"
  slack_username = "Login.gov"
  slack_icon = 
  sns_topic = var.slack_sns_topics
}

resource "aws_sns_topic" "slack_soc" {
  name = "slack-soc"
}

module "slack_default_login_events" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=a5e12e94d6038477782a370395702aa7f250562c"
  #source = "../../../identity-terraform/launch_template"
  
  lambda_name = lookup(local.slack_alerts["slack_default"], "lambda_name")
  lambda_description = lookup(local.slack_alerts["slack_default"], "lambda_description")
  slack_webhook = var.slack_webhook
  slack_channel = "login-soc"
  slack_username = "Login.gov"
  slack_icon = 
  sns_topic = var.slack_sns_topics
}

resource "aws_sns_topic" "opsgenie_alert" {
  name = "opsgenie-alert"
}





lambda_name        = 
lambda_description = 
slack_webhook      = 
slack_channel      = 
slack_username     = 
slack_icon         = 
slack_topic_arn    = 
