variable "rds_backup_retention_period" { default = "34" }
variable "rds_backup_window" { default = "08:00-08:34" }
# Changing engine or engine_version requires also changing any relevant uses of
# aws_db_parameter_group, which has a family attribute that tightly couples its
# parameter to the engine and version.
variable "rds_engine" { default = "postgres" }
variable "rds_engine_version" { default = "9.5.6" }
variable "rds_instance_class" { default = "db.t2.large" }
variable "rds_password" { }
variable "rds_storage" { default = "8" }
variable "rds_username" { }
variable "rds_maintenance_window" { default = "Sun:08:34-Sun:09:08" }
