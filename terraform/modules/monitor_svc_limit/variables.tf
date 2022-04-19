variable "sns_topic" {
  description = "ARN of SNS topic to send notification (in list format)"
  type        = list(string)
}

variable "function_input" {
  description = "JSON input that will be sent to Lambda function"
  type        = string
  default     = <<EOF
 {
	"action": "refesh&monitorTA"
 }
 EOF
}

variable "refresher_schedule" {
  description = "Frequency of TA refresher lambda execution"
  type        = string
  default     = "cron(0 14 * * ? *)"
}

variable "monitor_schedule" {
  description = "Frequency of TA monitor lambda execution"
  type        = string
  default     = "cron(10 14 * * ? *)"
}

variable "lambda_timeout" {
  description = "Timeout Value for Lambda"
  type        = number
  default     = 180
}

variable "refresher_lambda" {
  description = "Function Name for Lambda refreshing Trusted Advisor Checks"
  type        = string
  default     = "trustedadvisor-check-refresher"
}

variable "monitor_lambda" {
  description = "Function Name for Lambda monitoring Trusted Advisor Checks"
  type        = string
  default     = "trustedadvisor-check-monitor"
}
