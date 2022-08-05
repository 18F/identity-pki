variable "bucket_name" {
  description = "Bucket where logs live"
  type        = string
}

variable "database_name" {
  description = "Name of Athena database"
  type        = string
}

variable "kms_key" {
  description = "KMS key to use with the Athena database"
  type        = string
}


