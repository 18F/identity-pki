
# XXX This is disabled until https://github.com/newrelic/terraform-provider-newrelic/issues/744 is resolved
# XXX In the meantime, if you really want to deploy this, uncomment this stuff and download
# XXX the plugin by hand from https://github.com/newrelic/terraform-provider-newrelic/releases/tag/v2.1.2 and
# XXX put it into terraform/app/.terraform/plugins/darwin_amd64/
# module "newrelic" {
#   # once we go to terraform 0.13.x, we will be able to do this
#   # count = var.newrelic_alerts_enabled
#   source = "../modules/newrelic/"

#   enabled     = var.newrelic_alerts_enabled
#   region      = var.region
#   env_name    = var.env_name
#   events_in_last_ten_minutes_threshold = var.events_in_last_ten_minutes_threshold
# }
