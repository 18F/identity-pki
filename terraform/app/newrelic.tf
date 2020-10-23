# NOTE:  these s3 objects need to be uploaded with --content-type text/plain

locals {
  newrelic_keys = var.newrelic_alerts_enabled == 1 ? ["apikey", "admin_apikey", "account_id"] : []
}

data "aws_s3_bucket_object" "newrelic_key" {
  for_each = toset(local.newrelic_keys)

  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key = "common/newrelic_${each.key}"
}

provider "newrelic" {
  alias = "newrelic"
  region = "US"
  account_id = data.aws_s3_bucket_object.newrelic_key["account_id"].body
  api_key = data.aws_s3_bucket_object.newrelic_key["apikey"].body
  admin_api_key = data.aws_s3_bucket_object.newrelic_key["admin_apikey"].body
}


module "newrelic" {
  count  = var.newrelic_alerts_enabled
  source = "../modules/newrelic/"
  providers = {
    newrelic = newrelic.newrelic
  }

  staticsite_alerts_enabled = var.staticsite_newrelic_alerts_enabled
  elk_enabled               = var.elk_newrelic_alerts_enabled
  idp_enabled               = var.idp_newrelic_alerts_enabled
  enduser_enabled           = var.idp_enduser_newrelic_alerts_enabled
  dashboard_enabled         = var.dashboard_newrelic_alerts_enabled
  region                    = var.region
  env_name                  = var.env_name
  ten_min_alert_events      = var.ten_min_alert_events
  root_domain               = var.root_domain
  pivcac_alert_threshold    = var.pivcac_alert_threshold
  web_alert_threshold       = var.web_alert_threshold
  web_warn_threshold        = var.web_warn_threshold
  opsgenie_key_file         = var.opsgenie_key_file
  error_dashboard_site      = "${var.env_name}.${var.root_domain}"
}
