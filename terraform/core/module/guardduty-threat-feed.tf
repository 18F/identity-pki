module "guardduty_threat_feed" {
  source = "../../modules/guardduty_threat_feed"

  guardduty_threat_feed_name = var.guardduty_threat_feed_name
  region                     = var.region
  guardduty_days_requested   = var.guardduty_days_requested
  guardduty_frequency        = var.guardduty_frequency
  guardduty_threat_feed_code = "../../modules/guardduty_threat_feed/${var.guardduty_threat_feed_code}"
  logs_bucket                = local.s3_logs_bucket
  inventory_bucket_arn       = local.inventory_bucket_uw2_arn
}