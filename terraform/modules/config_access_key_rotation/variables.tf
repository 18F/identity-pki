variable "config_access_key_rotation_name" {
  description = "Name of the Config access key rotation, used to name other resources"
  type        = string
  default     = "cfg-access-key-rotation"
}

variable "config_access_key_rotation_code" {
  type        = string
  description = "Path of the compressed lambda source code. Relative to module path."
  default     = "config-access-key-rotation.zip"
}

variable "alarm_sns_topics" {
  type        = set(string)
  description = "List of SNS topics to alert to when alarms trigger"
}

variable "lambda_timeout" {
  type        = number
  default     = "900"
  description = "Timeout Value for Lambda"
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.12"
  description = "Runtime for Lambda"
}

variable "schedule" {
  type        = string
  description = "Cron expression for cloudwatch event rule schedule"
  default     = "cron(0 22 * * ? *)"
}

variable "cloudwatch_retention_days" {
  default     = 0
  description = <<EOM
Number of days to retain CloudWatch Logs for the Lambda function.
Defaults to 0 (never expire).
EOM
  type        = number
}
