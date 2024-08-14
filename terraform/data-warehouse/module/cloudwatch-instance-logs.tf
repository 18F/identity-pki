locals {
  cloudwatch_log_groups = merge(
    {
      "aide_log"                = "var/log/aide/aide.json",
      "amazon_ssm_agent"        = "var/log/amazon/ssm/amazon-ssm-agent.log",
      "amazon_ssm_agent_errors" = "var/log/amazon/ssm/errors.log",
      "apt_history"             = "var/log/apt/history.log",
      "audit"                   = "var/log/audit/audit.log",
      "auth"                    = "var/log/auth.log",
      "besclient"               = "var/log/besclient/besclient.log",
      "dpkg"                    = "var/log/dpkg.log",
      "endgame_install"         = "var/log/endgame_install.log",
      "kern"                    = "var/log/kern.log",
      "mail"                    = "var/log/mail.log",
      "messages_log"            = "var/log/messages",
      "nginx_passenger"         = "var/log/nginx/passenger.log",
      "syslog"                  = "var/log/syslog",
      "ubuntu_advantage"        = "var/log/ubuntu-advantage.log",
      "reporting_newrelic"      = "srv/reporting/shared/log/newrelic_agent.log",
      "reporting_production"    = "srv/reporting/shared/log/production.log",
      "reporting_workers"       = "srv/reporting/shared/log/workers.log",
  })
}

resource "aws_cloudwatch_log_group" "log" {
  for_each = local.cloudwatch_log_groups

  name              = join("_/", [var.env_name, each.value])
  retention_in_days = local.logs_retention_days
  skip_destroy      = var.prevent_tf_log_deletion

  tags = {
    environment = var.env_name
  }
}
