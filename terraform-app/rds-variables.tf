variable "rds_password" { }
variable "rds_engine" { default = "postgres" }
variable "rds_username" { }
variable "rds_storage" { default = "8" }
variable "rds_instance_class" { default = "db.t2.large" }
variable "rds_backup_retention_period" { default = "30" }
variable "rds_backup_window" { default = "06:00-06:30" }
