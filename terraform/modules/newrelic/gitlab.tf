resource "newrelic_synthetics_monitor" "gitlab_health" {
  count     = (var.enabled + var.gitlab_enabled) >= 2 ? 1 : 0
  name      = "${var.env_name} gitlab check"
  type      = "SIMPLE"
  frequency = 5
  status    = "ENABLED"
  locations = ["AWS_US_EAST_2"]

  uri               = "https://gitlab.${var.env_name}.${var.root_domain}"
  validation_string = "GitLab"
  verify_ssl        = true
}
resource "newrelic_synthetics_alert_condition" "gitlab_health" {
  count     = (var.enabled + var.gitlab_enabled) >= 2 ? 1 : 0
  policy_id = newrelic_alert_policy.low[0].id

  name       = "${var.env_name} gitlab health failure"
  monitor_id = newrelic_synthetics_monitor.gitlab_health[0].id
}
