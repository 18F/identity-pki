variable "name" {
  type = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "suffix" {
  description = "Optional suffix for use with non-IdP instances"
  type        = string
  default     = ""
}
variable "rds_engine" {
  type = string
}

variable "rds_engine_version" {
  type = string
}
