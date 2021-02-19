variable "name" {
    type = string
}
variable "env_name" {
    description = "Environment name"
    type = string
}

variable "rds_engine" {
  type = string
}

variable "rds_engine_version" {
  type = string
}

variable "rds_engine_version_short" {
  type = string
}
