data "aws_caller_identity" "current" {}

variable "bucket_name" {
  description = "Bucket where logs live"
  type        = string
}

variable "bucket_path" {
  description = "Path where logs live"
  type        = string
  default     = "logs/"
}

variable "database_name" {
  description = "Name of Athena database"
  type        = string
}

variable "env_name" {
  description = "Environment Name"
  type        = string
}

variable "kms_key" {
  description = "KMS key to use with the Athena database"
  type        = string
}

variable "kms_resources" {
  description = "List of resources the lambda is allowed to access with kms"
  type        = list(any)
}

variable "lambda_description" {
  description = "Lambda description"
  type        = string
  default     = "Converts Kinesis log streams into a format readable by Athena"
}

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "events-log-processor"
}

variable "lambda_memory" {
  description = "Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments"
  type        = number
  default     = 512
}

variable "lambda_ephemeral_storage" {
  description = "Used to expand the total amount of Ephemeral storage available, beyond the default amount of 512MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function"
  type        = number
  default     = 30
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "log_processor_lambda" {
  description = "Name of lambda for processing logs"
  type        = string
  default     = "athena_events_log_processor_lambda"
}

variable "process_logs" {
  description = "Is the log format json?"
  type        = bool
  default     = false
}

variable "region" {
  description = "AWS region identifier"
  type        = string
  default     = "us-west-2"
}

variable "source_arn" {
  description = "Arn for S3 Lambda trigger"
  type        = string
}

