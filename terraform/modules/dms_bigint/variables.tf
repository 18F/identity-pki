variable "env_name" {
  description = "Name of application environment"
  type        = string
}

variable "rds_username" {
  description = "Username for rds instances"
  type        = string
}

variable "rds_password" {
  description = "Password for rds instances"
  type        = string
}

variable "cert_bucket" {
  description = "Bucket for ca file"
  type        = string
}

variable "source_db_address" {
  description = "Source database address"
  type        = string
}

variable "target_db_address" {
  description = "Source database address"
  type        = string
}

variable "source_db_allocated_storage" {
  description = "Source database allocated storage"
  type        = string
}

variable "source_db_availability_zone" {
  description = "Source database availability zone"
  type        = string
}

variable "source_db_instance_class" {
  description = "Source database instance class"
  type        = string
}

variable "rds_kms_key_arn" {
  description = "KMS key used to encrypt rds"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group ids"
  type        = list(any)
}

variable "subnet_ids" {
  description = "List of subnet ids"
  type        = list(any)
}

variable "logger_severity" {
  description = "Log level for dms"
  type        = string
  default     = "LOGGER_SEVERITY_INFO"
}

