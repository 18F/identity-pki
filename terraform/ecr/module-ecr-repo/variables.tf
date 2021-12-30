variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "env" {
  description = "Environment name"
}

variable "ecr_repo_name" {
  description = "Name of ECR repo"
  type        = string
}

variable "ecr_repo_tag_mutability" {
  description = "The container tag mutability setting for the repository (MUTABLE\IMMUTABLE)"
  default     = "MUTABLE"
  type        = string
}

variable "tags" {
  description = "The tags applied to the ECR repo"
  type        = map(string)
}

variable "encryption_type" {
  description = "Encryption_type for the repository (AES256\KMS)"
  default     = "AES256"
  type        = string
}

variable "kms_key" {
  description = "ARN of the KMS key to use when encryption type is KMS (will use default key if not specified)"
  type        = string
}
