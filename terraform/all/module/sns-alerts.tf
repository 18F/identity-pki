data "aws_s3_bucket_object" "slack_webhook" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "${local.common_account_name}/slackwebhook"
}

# TODO: decide if we use common/ for each account, or use the
# common_account_name logic as used above for the slack_webhook object
data "aws_s3_bucket_object" "opsgenie_sns_apikey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/opsgenie_sns_apikey"
}

# TODO: use for_each to create resources AND modules
# once we move to Terraform 0.13
resource "aws_sns_topic" "slack_events" {
  name = "slack-events"
}

module "slack_login_events" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=897cd9f749ead05a97b0f904a5dedfe83d9a9566"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "snstoslack_login_events"
  lambda_description = "Sends messages to #login-events Slack channel via SNS subscription."
  slack_webhook_url  = data.aws_s3_bucket_object.slack_webhook.body
  slack_channel      = "login-events"
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_events.arn
}

resource "aws_sns_topic" "slack_otherevents" {
  name = "slack-otherevents"
}

module "slack_login_otherevents" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=897cd9f749ead05a97b0f904a5dedfe83d9a9566"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "snstoslack_login_otherevents"
  lambda_description = "Sends messages to #login-otherevents Slack channel via SNS subscription."
  slack_webhook_url  = data.aws_s3_bucket_object.slack_webhook.body
  slack_channel      = "login-otherevents"
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_otherevents.arn
}

resource "aws_sns_topic" "slack_soc" {
  name = "slack-soc"
}

module "slack_login_soc" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=897cd9f749ead05a97b0f904a5dedfe83d9a9566"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "snstoslack_login_soc"
  lambda_description = "Sends messages to #login-soc Slack channel via SNS subscription."
  slack_webhook_url  = data.aws_s3_bucket_object.slack_webhook.body
  slack_channel      = "login-soc-events"
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_soc.arn
}

resource "aws_sns_topic" "opsgenie_alert" {
  name = "opsgenie-alert"
}

resource "aws_sns_topic_subscription" "opsgenie_alert" {
  topic_arn = aws_sns_topic.opsgenie_alert.arn
  endpoint_auto_confirms = true
  protocol  = "https"
  endpoint  = "https://api.opsgenie.com/v1/json/cloudwatch?apiKey=${data.aws_s3_bucket_object.opsgenie_sns_apikey.body}"
}

# us-east-1
resource "aws_sns_topic" "slack_events_use1" {
  provider = aws.use1
  name = "slack-events"
}

module "slack_login_events_use1" {
  providers = {
    aws = aws.use1
  }
  source = "github.com/18F/identity-terraform//slack_lambda?ref=897cd9f749ead05a97b0f904a5dedfe83d9a9566"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "snstoslack_login_events"
  lambda_description = "Sends messages to #login-events Slack channel via SNS subscription."
  slack_webhook_url  = data.aws_s3_bucket_object.slack_webhook.body
  slack_channel      = "login-events"
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_events_use1.arn
}

resource "aws_sns_topic" "slack_otherevents_use1" {
  provider = aws.use1
  name = "slack-otherevents"
}

module "slack_login_otherevents_use1" {
  providers = {
    aws = aws.use1
  }
  source = "github.com/18F/identity-terraform//slack_lambda?ref=897cd9f749ead05a97b0f904a5dedfe83d9a9566"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "snstoslack_login_otherevents"
  lambda_description = "Sends messages to #login-otherevents Slack channel via SNS subscription."
  slack_webhook_url  = data.aws_s3_bucket_object.slack_webhook.body
  slack_channel      = "login-otherevents"
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_otherevents_use1.arn
}

resource "aws_sns_topic" "slack_soc_use1" {
  provider = aws.use1
  name = "slack-soc"
}

module "slack_login_soc_use1" {
  providers = {
    aws = aws.use1
  }
  source = "github.com/18F/identity-terraform//slack_lambda?ref=897cd9f749ead05a97b0f904a5dedfe83d9a9566"
  #source = "../../../../identity-terraform/slack_lambda"
  
  lambda_name        = "snstoslack_login_soc"
  lambda_description = "Sends messages to #login-soc Slack channel via SNS subscription."
  slack_webhook_url  = data.aws_s3_bucket_object.slack_webhook.body
  slack_channel      = "login-soc-events"
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.slack_soc_use1.arn
}

resource "aws_sns_topic" "opsgenie_alert_use1" {
  provider = aws.use1
  name = "opsgenie-alert"
}

resource "aws_sns_topic_subscription" "opsgenie_alert_use1" {
  provider = aws.use1
  topic_arn = aws_sns_topic.opsgenie_alert_use1.arn
  endpoint_auto_confirms = true
  protocol  = "https"
  endpoint  = "https://api.opsgenie.com/v1/json/cloudwatchevents?apiKey=${data.aws_s3_bucket_object.opsgenie_sns_apikey.body}"
}
