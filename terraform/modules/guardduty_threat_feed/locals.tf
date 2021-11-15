locals {
  guardduty_feedname_iam = replace(var.guardduty_threat_feed_name, "/[^a-zA-Z0-9 ]/", "")
  gd_s3_bucket           = "login-gov.gd-${var.guardduty_threat_feed_name}.${data.aws_caller_identity.current.account_id}-${var.region}"
}