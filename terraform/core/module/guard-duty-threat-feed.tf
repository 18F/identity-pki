module "guard_duty_threat_feed" {
  source = "../../modules/guard_duty_threat_feed"

  guard_duty_threat_feed_name = var.guard_duty_threat_feed_name
  region                      = var.region
  guard_duty_days_requested   = var.guard_duty_days_requested
  guard_duty_frequency        = var.guard_duty_frequency
  guard_duty_threat_feed_code = "../../modules/guard_duty_threat_feed/${var.guard_duty_threat_feed_code}"
  logs_bucket                 = local.s3_logs_bucket
  inventory_bucket_arn        = local.inventory_bucket_uw2_arn
}