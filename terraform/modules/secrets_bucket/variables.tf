variable "region" {
  description = "Region to create the secrets bucket in"
  default     = "us-west-2"
}

variable "bucket_name_prefix" {
  description = "Base name for the secrets bucket to create"
}

variable "secrets_bucket_type" {
  description = "Type of secrets stored in this bucket"
}

variable "logs_bucket" {
  description = "Name of the bucket to store access logs in"
}

variable "bucket_name" {
  description = "Bucket Name"
}

variable "use_kms" {
  default     = true
  description = "Whether to encrypt the bucket with KMS"
}

variable "force_destroy" {
  default     = false
  description = "Allow destroy even if bucket contains objects"
}

variable "policy" {
  default     = ""
  description = "Bucket policy"
}

variable "sse_algorithm" {
  default     = "aws:kms"
  description = "S3 Server-side Encryption Algorithm"
}
