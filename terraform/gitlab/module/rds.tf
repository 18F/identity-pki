# RDS resources for gitlab live here

resource "aws_db_instance" "gitlab" {
  allocated_storage = var.rds_storage_gitlab
  engine            = var.rds_engine
  engine_version    = var.rds_engine_version
  instance_class    = var.rds_instance_class

  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  db_subnet_group_name    = aws_db_subnet_group.gitlab.id
  identifier              = "${var.name}-${var.env_name}-gitlab"
  maintenance_window      = var.rds_maintenance_window
  multi_az                = true
  parameter_group_name    = module.gitlab_rds_usw2.rds_parameter_group_name
  password                = var.rds_password # change this by hand after creation
  username                = var.rds_username
  storage_encrypted       = true
  storage_type            = var.rds_storage_type_gitlab
  iops                    = var.rds_iops_gitlab
  db_name                 = "gitlabhq_production"

  # we want to push these via Terraform now
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true

  tags = {
    Name = "${var.name}-${var.env_name}-gitlab"
  }

  vpc_security_group_ids = [aws_security_group.db.id]

  # send logs to cloudwatch
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # If you want to destroy your database, you need to do this in two phases:
  # 1. Uncomment `skip_final_snapshot=true` and
  #    comment `prevent_destroy=true` and `deletion_protection = true` below.
  # 2. Perform a terraform/deploy "apply" with the additional
  #    argument of "-target=aws_db_instance.idp" to mark the database
  #    as not requiring a final snapshot.
  # 3. Perform a terraform/deploy "destroy" as needed.
  #
  #skip_final_snapshot = true
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = [password]
  }

  deletion_protection = true
}

output "gitlab_db_endpoint" {
  value = aws_db_instance.gitlab.endpoint
}

module "gitlab_rds_usw2" {
  source = "../../modules/idp_rds"
  providers = {
    aws = aws.usw2
  }
  env_name           = var.env_name
  name               = var.name
  rds_engine         = var.rds_engine
  rds_engine_version = var.rds_engine_version
  pgroup_params      = var.pgroup_params
}

resource "aws_db_subnet_group" "gitlab" {
  description = "${var.env_name} subnet group for gitlab"
  name        = "${var.name}-db-${var.env_name} gitlab"
  subnet_ids  = [aws_subnet.db1.id, aws_subnet.db2.id]

  tags = {
    Name = "${var.name}-${var.env_name} gitlab"
  }
}

resource "aws_s3_object" "gitlab_db_host" {
  bucket  = data.aws_s3_bucket.secrets.id
  key     = "${var.env_name}/gitlab_db_host"
  content = aws_db_instance.gitlab.address

  source_hash = md5(aws_db_instance.gitlab.address)
}

output "gitlab_db_host" {
  value = aws_db_instance.gitlab.address
}
