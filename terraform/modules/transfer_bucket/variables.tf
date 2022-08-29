variable "region" {
  description = "Region to create the secrets bucket in"
  default     = "us-west-2"
}

variable "bucket_name_prefix" {
  description = "Base name for the secrets bucket to create"
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

variable "sse_algorithm" {
  default     = "aws:kms"
  description = "S3 Server-side Encryption Algorithm"
}

variable "permitted_ip_addresses" {
  type = list(any)
  default = [
    "159.142.0.0/16", # GSA CIDR Block
  ]
  description = "Permitted IP Address ranges to access transfer bucket"
}

