
module "newrelic" {
  # once we go to terraform 0.13.x, we will be able to do this
  # count = var.newrelic_alerts_enabled
  source = "../modules/newrelic/"

  enabled     = var.newrelic_alerts_enabled
  region      = var.region
  env_name    = var.env_name
  events_in_last_ten_minutes_threshold = var.events_in_last_ten_minutes_threshold
}
