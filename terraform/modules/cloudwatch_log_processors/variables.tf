data "aws_caller_identity" "current" {}

variable "bucket_name" {
  description = "Bucket where logs live"
  type        = string
}

variable "bucket_path" {
  description = "Path where logs live"
  type        = string
  default     = "logs"
}

variable "env_name" {
  description = "Environment Name"
  type        = string
}

variable "kms_resources" {
  description = "List of resources the lambda is allowed to access with kms"
  type        = list(any)
}

variable "log_processor_lambda" {
  description = "Name of lambda for processing logs"
  type        = string
  default     = "athena_events_log_processor_lambda"
}

variable "region" {
  description = "AWS region identifier"
  type        = string
  default     = "us-west-2"
}

variable "lambda_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "events-log-processor"
}

variable "lambda_description" {
  description = "Lambda description"
  type        = string
  default     = "Converts Kinesis log streams into a format readable by Athena"
}

variable "lambda_timeout" {
  description = "Timeout for Lambda function"
  type        = number
  default     = 3
}

variable "lambda_memory" {
  description = "Memory allocated to Lambda function, 128MB to 3,008MB in 64MB increments"
  type        = number
  default     = 128
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "source_arn" {
  description = "Arn for S3 Lambda trigger"
  type        = string
}


