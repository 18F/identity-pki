locals {
  inventory_bucket_arn = join(".", [
    "arn:aws:s3:::${var.bucket_name_prefix}.s3-inventory",
    "${data.aws_caller_identity.current.account_id}-${var.region}"
  ])
}

variable "region" {
  description = "Region to create the secrets bucket in"
  default     = "us-west-2"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Base name for the secrets bucket to create"
  type        = string
}

variable "secrets_bucket_type" {
  description = "Type of secrets stored in this bucket"
  type        = string
}

variable "logs_bucket" {
  description = "Name of the bucket to store access logs in"
  type        = string
}

variable "bucket_name" {
  description = "Bucket Name"
  type        = string
}

variable "use_kms" {
  default     = true
  description = "Whether to encrypt the bucket with KMS"
  type        = bool
}

variable "force_destroy" {
  default     = false
  description = "Allow destroy even if bucket contains objects"
  type        = bool
}

variable "policy" {
  default     = ""
  description = "An additonal Bucket policy in JSON format"
  type        = string

  validation {
    condition = (
      length(var.policy) != 0 ?
      can(jsondecode(var.policy))
      : true
    )
    error_message = "Bucket Policy is not valid JSON"
  }
}

variable "sse_algorithm" {
  default     = "aws:kms"
  description = "S3 Server-side Encryption Algorithm"
  type        = string
}

variable "object_ownership" {
  description = <<EOM
Object Ownership configuration for aws_s3_bucket_ownership_controls resource.
Can be set to BucketOwnerPreferred, BucketOwnerEnforced, or ObjectWriter.
EOM
  type        = string
  default     = "BucketOwnerPreferred"
  validation {
    condition = contains(
      ["BucketOwnerPreferred", "BucketOwnerEnforced", "ObjectWriter"],
      var.object_ownership
    )
    error_message = <<EOM
Object Ownership configuration must be set to one of:
BucketOwnerPreferred, BucketOwnerEnforced, or ObjectWriter.
EOM
  }
}
