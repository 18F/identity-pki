variable "name" {
  type    = string
  default = "login"
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "db_identifier" {
  type        = string
  description = "Unique identifier for the database (e.g. default/primary/etc.)"
  default     = "idp"
}

variable "db_name_override" {
  type        = string
  description = <<EOM
Manually-specified name for the Aurora cluster. Will override the
default pattern of env_name-db_identifier unless left blank.
EOM
  default     = ""
}

variable "db_engine" {
  type        = string
  description = "Name of the DB engine."
  default     = "postgres"
  validation {
    condition = contains(
      ["postgres", "aurora", "aurora-mysql", "aurora-postgresql"], var.db_engine
    )
    error_message = <<EOM
Invalid value for var.db_engine; must be one of the following:
"postgres", "aurora", "aurora-mysql", "aurora-postgresql"
EOM
  }
}

variable "db_engine_version" {
  type        = string
  description = "Version number (e.g. ##.#) of db_engine to use"
  default     = "13.9"
}

variable "pgroup_params" {
  type        = list(any)
  description = "Parameter names/values/methods for the force_ssl parameter group"
  default     = []
}

variable "cluster_pgroup_params" {
  type        = list(any)
  description = <<EOM
List of parameters to configure for the AuroraDB cluster parameter group.
Include name, value, and apply method (will default to 'immediate' if not set).
EOM
  default     = []
}

variable "db_pgroup_params" {
  type        = list(any)
  description = <<EOM
List of parameters to configure for the AuroraDB instance parameter group.
Include name, value, and apply method (will default to 'immediate' if not set).
EOM
  default     = []
}
