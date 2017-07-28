variable "region" {
    description = "Region to create the secrets bucket in"
    default = "us-west-2"
}

variable "bucket_name_prefix" {
    description = "Base name for the secrets bucket to create"
}

variable "use_kms" {
    default = true
    description = "Whether to encrypt the bucket with KMS"
}

variable "force_destroy" {
    default = false
    description = "Allow destroy even if bucket contains objects"
}
