module "analytics" {
  source = "../terraform-modules/analytics/"
  env_name = "${var.env_name}"
  redshift_master_password = "${var.redshift_master_password}"
  vpc_cidr_block =  "${var.vpc_cidr_block}"
  analytics_version = "${var.analytics_version}"
  region = "${var.region}"
  kms_key_id = "${var.kms_key_id}"
}
