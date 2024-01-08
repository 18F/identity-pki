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

variable "sns_topic_alert_critical" {
  description = "Name of the SNS topic to send critical alerts to"
  type        = string
  default     = "slack-otherevents"
}

variable "sns_topic_alert_warning" {
  description = "Name of the SNS topic to send warnings to"
  type        = string
  default     = "slack-otherevents"
}

variable "pinpoint_error_alarm_threshold" {
  description = "Number of SMS errors for triggering an alarm"
  default     = 50
}

variable "pinpoint_spend_limit" {
  description = "USD monthly spend limit for pinpoint application. Increased via support ticket."
}

variable "pinpoint_event_logger_lambda_name" {
  description = "Name of the PinPoint to CloudWatch logger"
  type        = string
  default     = "pinpoint_event_logger"
}

variable "sms_support_api_endpoint" {
  type        = string
  description = <<EOM
  The Login.gov IDP API endpoint that contains the telephony support information for the given environment.
  EOM
}

variable "sms_unexpected_country_alarm_default_threshold" {
  type        = number
  default     = 100
  description = <<EOM
  This is the default threshold for number of SMS message sent hourly.
  Any country (other than those in the ignored_list or overridden in sms_unexpected_individual_country_alarm_thresholds) going over the threshold
  limit in an hour will trigger an alert to slack"
  EOM
}

variable "sms_unexpected_individual_country_alarm_thresholds" {
  type = map(string)
  default = {
  }

  description = <<EOM
  Individual per-country/region (in ISO format) limits for SMS.
  This allows us to raise or lower the expected threshold.
  EOM
}

variable "ignored_countries" {
  type        = string
  description = "Countries (in ISO format) that should be excluded from the query for high usage"
  default     = "US,PR,MX,CA,GU"
}
