# Stub remote config needed for terraform 0.9.*
terraform {
  backend "s3" {
  }
}

module "analytics" {
  source = "../terraform-modules/analytics/"
  env_name = "${var.env_name}"
  jumphost_cidr_block = "${var.jumphost_cidr_block}"
  redshift_master_password = "${var.redshift_master_password}"
  vpc_cidr_block =  "${var.vpc_cidr_block}"
  analytics_version = "${var.analytics_version}"
  region = "${var.region}"
  kms_key_id = "${var.kms_key_id}"
  num_redshift_nodes = "${var.num_redshift_nodes}"
  name = "${var.name}"
  wlm_json_configuration = "${var.wlm_json_configuration}"
}
