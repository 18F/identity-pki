variable "region" {
  description = "AWS region, used for S3 bucket names"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform-locks'"
}

variable "manage_state_bucket" {
  description = <<EOM
Whether to manage the TF remote state bucket and lock table.
Set this to false if you want to skip this for bootstrapping.
EOM
  default     = 1
}

variable "env" {
  description = "Name of this account environment (e.g. sandbox)"
}

variable "pinpoint_app_name" {
  description = "Name of the pinpoint app"
}

variable "opsgenie_devops_high_endpoint" {
  description = "OpsGenie endpoint to use for high priority alerting from SNS"
}

variable "sns_topic_arn_slack_events" {
  description = <<EOM
ARN of the SNS topic used for sending messages to Slack #login-events.

This is created manually because the subscription itself has to be created
manually since Terraform does not support creating email subscriptions.
EOM
}

variable "pinpoint_error_alarm_threshold" {
  description = "Number of SMS errors for triggering an alarm"
  default     = 50
}

variable "pinpoint_spend_limit" {
  description = "USD monthly spend limit for pinpoint application. Increased via support ticket."
}
