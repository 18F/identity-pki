module "big_int_migration" {
  count  = var.enable_dms_migration ? 1 : 0
  source = "../modules/dms_bigint"

  env_name     = var.env_name
  rds_password = var.rds_password
  rds_username = var.rds_username
  cert_bucket  = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"

  source_db_address           = module.idp_aurora_from_rds[0].primary_instance.endpoint
  target_db_address           = module.idp_aurora_from_rds[0].primary_instance.endpoint
  source_db_allocated_storage = 3000
  source_db_availability_zone = module.idp_aurora_from_rds[0].primary_instance.availability_zone
  source_db_instance_class    = module.idp_aurora_from_rds[0].primary_instance.instance_class
  rds_kms_key_arn             = module.idp_rds_usw2.rds_kms_key_arn

  subnet_ids = aws_db_subnet_group.aurora[count.index].subnet_ids

  vpc_security_group_ids = [
    aws_security_group.db.id,
    aws_security_group.idp.id
  ]

  depends_on = [
    module.idp_aurora_from_rds
  ]

}