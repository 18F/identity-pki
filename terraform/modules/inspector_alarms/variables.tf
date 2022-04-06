variable "alarm_name" {
  description = "Name used to create the Cloudwatch event rule"
  type        = string
}

variable "sns_target_arn" {
  description = "An ARN to notify when the alarm fires"
  type        = string
}
