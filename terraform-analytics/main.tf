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
  # TODO use terraform locals to compute this once we upgrade to 0.10.*
  analytics_log_bucket_name = "${ var.legacy_log_bucket_name ? "login-gov-${var.env_name}-analytics-logs" : "login-gov-analytics-logs-${var.env_name}.${data.aws_caller_identity.current.account_id}-${var.region}" }"
}
