variable "rds_password" { }
variable "rds_engine" { default = "postgres" }
variable "rds_username" { }
variable "rds_storage" { default = "8" }
variable "rds_instance_class" { default = "db.t2.micro" }
variable "rds_identifier" { default = "login-dev" }
