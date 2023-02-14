# use AWS KMS key for DMS module
data "aws_kms_key" "dms_alias" {
  key_id = "alias/aws/dms"
}

module "big_int_migration" {
  count  = var.enable_dms_migration ? 1 : 0
  source = "../modules/dms_bigint"

  env_name     = var.env_name
  rds_password = var.rds_password
  rds_username = var.rds_username
  cert_bucket  = local.secrets_bucket

  source_db_address           = module.idp_aurora_from_rds[0].writer_instance_endpoint
  target_db_address           = module.idp_aurora_from_rds[0].writer_instance_endpoint
  source_db_allocated_storage = 3000
  source_db_availability_zone = module.idp_aurora_from_rds[0].writer_instance_az
  source_db_instance_class    = var.rds_instance_class_aurora
  rds_kms_key_arn             = data.aws_kms_key.dms_alias.arn

  subnet_ids = aws_db_subnet_group.aurora.subnet_ids

  vpc_security_group_ids = [
    aws_security_group.db.id,
    aws_security_group.idp.id
  ]

  depends_on = [
    module.idp_aurora_from_rds
  ]

}