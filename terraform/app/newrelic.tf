
module "newrelic" {
  source = "../modules/newrelic/"

  enabled     = var.newrelic_alerts_enabled
  region      = var.region
  env_name    = var.env_name
}