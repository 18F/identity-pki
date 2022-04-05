variable "aws_region" {
  type        = string
  description = "AWS Region"
}


variable "sns_topic" {
  type        = list(string)
  description = "SNS topic"
}

variable "function_input" {
  description = "JSON input that will be sent to Lambda function"
  default     = <<EOF
 {
	"action": "refesh&monitorTA"
 }
 EOF
}

variable "refresher_trigger_schedule" {
  description = "Frequency of TA refresher lambda execution"

}

variable "monitor_trigger_schedule" {
  description = "Frequency of TA monitor lambda execution"

}


variable "lambda_timeout" {
  type        = number
  default     = "180"
  description = "Timeout Value for Lambda"
}

variable "ta_refresher_lambda_name" {
  type        = string
  default     = "ta_refresher_lambda"
  description = "TA refresher Lambda"
}


variable "ta_monitor_lambda_name" {
  type        = string
  default     = "ta_monitor_lambda"
  description = "TA monitor Lambda"
}
