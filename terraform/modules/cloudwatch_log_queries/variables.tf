variable "region" {
  default = "us-west-2"
}

variable "env_name" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "db_types" {
  description = <<EOM
Map of database types, where the key is the type of database,
(e.g. 'idp', 'analytics') and the value is the identifier for
the database cluster ('idp-uw2')
  EOM
  type        = map(any)
}
