module "guard_duty_threat_feed" {
  source = "../../modules/guard_duty_threat_feed"

  ###################### START ######################
  guard_duty_threat_feed_name        = var.guard_duty_threat_feed_name
  account_id                         = var.master_account_id
  aws_region                         = var.region
  days_requested                     = var.days_requested
  frequency                          = var.frequency
  guard_duty_threat_feed_public_key  = var.guard_duty_threat_feed_public_key
  guard_duty_threat_feed_private_key = var.guard_duty_threat_feed_private_key
  guard_duty_threat_feed_code        = var.guard_duty_threat_feed_code
  ###################### END ########################
}