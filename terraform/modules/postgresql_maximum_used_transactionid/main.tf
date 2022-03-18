
resource "random_string" "suffix" {
    length  = 5
    special = false
  }
resource "aws_sns_topic" "sns_topic_new" {
    name = "sns-notify-lambda-${random_string.suffix.result}"
  }

module "slack_login_otherevents" {
  source = "github.com/18F/identity-terraform//slack_lambda?ref=main"
  
  lambda_name        = "MaximumUsedTransactionIDs_Notify_${random_string.suffix.result}"
  lambda_description = "Sends messages to Slack channel via SNS subscription."
  slack_webhook_url_parameter  = var.slack_webhook_url_parameter
  slack_channel      = var.slack_channel
  slack_username     = var.slack_username
  slack_icon         = var.slack_icon
  slack_topic_arn    = aws_sns_topic.sns_topic_new.arn
}


### Cloudwatch Alarm montioring Database ###

 resource "aws_cloudwatch_metric_alarm" "MaximumUsedTransactionIDs" {
  alarm_name          = "DB_MaximumUsedTransactionIDs_Alert"
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = var.datapoints_to_alarm
  evaluation_periods  = var.evaluation_periods
  metric_name         = "MaximumUsedTransactionIDs"
  namespace           = "AWS/RDS"
  period              = var.period
  statistic           = var.statistic
  threshold           = var.transaction_id_threshold
  alarm_description   = "Maximum used transaction IDs"
  actions_enabled     = "true"
  alarm_actions      = [aws_sns_topic.sns_topic_new.arn, var.alarm_actions]
  #alarm_actions       = [local.high_priority_alarm_actions, aws_sns_topic.sns_topic_new.arn]
  dimensions = {
    DBInstanceIdentifier = var.db_name
  }
}
