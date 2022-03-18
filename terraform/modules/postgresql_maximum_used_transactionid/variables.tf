#variable "lambda_name" {
#  description = "Name of the Lambda function"
#  type        = string
#  default     = "SnsToSlack"
#}

variable "lambda_description" {
  description = "Lambda description"
  type        = string
  default     = "Sends a message sent to an SNS topic to Slack."
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function"
  type        = number
  default     = 120
}

variable "lambda_memory" {
  description = "Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments"
  type        = number
  default     = 128
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.8"
}

variable "slack_webhook_url_parameter" {
  description = "Slack Webhook URL SSM Parameter."
  type        = string
  default     = "/account/slack/webhook/url"
}

variable "slack_channel" {
  description = "Name of the Slack channel to send messages to. DO NOT include the # sign."
  type        = string
  default     = "login-otherevents"
}

variable "slack_username" {
  description = "Displayed username of the posted message."
  type        = string
  default     = "PostgreSQLMaximumUsedTransactionIDsAlert"
}

variable "slack_icon" {
  description = "Displayed icon used by Slack for the message."
  type        = string
  default     = "fire"
}


#---------------------------------------------------
# Variables for Cloudwatch Alarm
#---------------------------------------------------

variable "datapoints_to_alarm" {
  type        = number
  description = "Cloudwatch alarm datapoints to monitor"
  default     = "1"
}

variable "evaluation_periods" {
  type        = number
  description = "Cloudwatch alarm evaluation period"
  default     = "1"
}

variable "period" {
  type        = number
  description = "Cloudwatch alarm period"
  default     = "300"
}

variable "statistic" {
  type        = string
  description = "Cloudwatch alarm statistic"
  default     = "Average"
}

variable "transaction_id_threshold" {
  type        = number
  description = "Threshold for the maximum transaction id for triggering cloudwatch alarm"
  default     = "80"
}

variable "alarm_actions" {
  type        = string
  description = "ARN of SNS topic for high-priority pages"

}

#---------------------------------------------------
# Variables for Database
#---------------------------------------------------

variable "db_name" {
  type        = string
  description = "Database name to be monitored by the Cloudwatch Alarm"

}
