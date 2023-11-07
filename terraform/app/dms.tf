# use AWS KMS key for DMS module
data "aws_kms_key" "dms_alias" {
  key_id = "alias/aws/dms"
}

module "dms" {
  count  = (var.enable_dms_migration || var.enable_dms_analytics) ? 1 : 0
  source = "../modules/dms"

  env_name     = var.env_name
  rds_password = var.rds_password
  rds_username = var.rds_username
  cert_bucket  = local.secrets_bucket

  source_db_address           = module.idp_aurora_uw2.writer_instance_endpoint
  target_db_address           = module.idp_aurora_uw2.writer_instance_endpoint
  source_db_allocated_storage = 3000
  source_db_availability_zone = module.idp_aurora_uw2.writer_instance_az
  source_db_instance_class    = var.rds_instance_class
  rds_kms_key_arn             = data.aws_kms_key.dms_alias.arn

  subnet_ids = module.network_uw2.db_subnet_ids

  vpc_security_group_ids = [
    module.network_uw2.db_security_group,
    aws_security_group.idp.id
  ]

  depends_on = [
    module.idp_aurora_uw2
  ]

}
