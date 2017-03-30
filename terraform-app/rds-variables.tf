variable "rds_backup_retention_period" { default = "34" }
variable "rds_backup_window" { default = "08:00-08:34" }
variable "rds_engine" { default = "postgres" }
variable "rds_instance_class" { default = "db.t2.large" }
variable "rds_password" { }
variable "rds_storage" { default = "8" }
variable "rds_username" { }
variable "rds_maintenance_window" { default = "Sun:08:34-Sun:09:08" }
