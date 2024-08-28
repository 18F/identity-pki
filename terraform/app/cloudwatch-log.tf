locals {
  retention_days = (local.acct_type == "prod" ? "2192" : "30")

  cloudwatch_log_groups = merge(
    {
      "idp_events"                  = "srv/idp/shared/log/events.log",
      "idp_kms"                     = "srv/idp/shared/log/kms.log",
      "idp_newrelic_agent"          = "srv/idp/shared/log/newrelic_agent.log",
      "idp_production"              = "srv/idp/shared/log/production.log",
      "idp_puma"                    = "srv/idp/shared/log/puma.log",
      "idp_puma_err"                = "srv/idp/shared/log/puma_err.log",
      "idp_telephony"               = "srv/idp/shared/log/telephony.log",
      "idp_workers"                 = "srv/idp/shared/log/workers.log",
      "pki_newrelic_agent"          = "srv/pki-rails/shared/log/newrelic_agent.log",
      "pki_production"              = "srv/pki-rails/shared/log/production.log",
      "pki_puma"                    = "srv/pki-rails/shared/log/puma.log",
      "pki_puma_err"                = "srv/pki-rails/shared/log/puma_err.log",
      "aide_aide"                   = "var/log/aide/aide.json",
      "amazon_ssm_amazon_ssm_agent" = "var/log/amazon/ssm/amazon-ssm-agent.log",
      "amazon_ssm_errors"           = "var/log/amazon/ssm/errors.log",
      "amazon_ssm_hibernate"        = "var/log/amazon/ssm/hibernate.log",
      "apt_history"                 = "var/log/apt/history.log",
      "audit_audit"                 = "var/log/audit/audit.log",
      "auth"                        = "var/log/auth.log",
      "besclient_besclient"         = "var/log/besclient/besclient.log",
      "dpkg"                        = "var/log/dpkg.log",
      "kern"                        = "var/log/kern.log",
      "mail"                        = "var/log/mail.log",
      "messages"                    = "var/log/messages",
      "nginx_access"                = "var/log/nginx/access.log",
      "nginx_error"                 = "var/log/nginx/error.log",
      "nginx_status"                = "var/log/nginx/nginx_status.log",
      "nginx_puma_status"           = "var/log/nginx/puma_status.log",
      "postgresql_pgbouncer"        = "var/log/postgresql/pgbouncer.log",
      "syslog"                      = "var/log/syslog",
      "ubuntu_advantage"            = "var/log/ubuntu-advantage.log",
    },
    var.apps_enabled == 1 ? {
      "dashboard_newrelic_agent" = "srv/dashboard/shared/log/newrelic_agent.log",
      "dashboard_production"     = "srv/dashboard/shared/log/production.log",
      "dashboard_puma"           = "srv/dashboard/shared/log/puma.log",
      "dashboard_puma_err"       = "srv/dashboard/shared/log/puma_err.log",
    } : {}
  )
}

resource "aws_cloudwatch_log_group" "log" {
  for_each = local.cloudwatch_log_groups

  name              = join("_/", [var.env_name, each.value])
  retention_in_days = local.retention_days
  skip_destroy      = var.prevent_tf_log_deletion

  tags = {
    environment = var.env_name
  }
}

# separated as it's a different name/retention_in_days value
# TODO: determine if retention can be changed + can be moved into group above
resource "aws_cloudwatch_log_group" "dns_query_log" {
  name              = "${var.env_name}/dns/query"
  retention_in_days = 365
  skip_destroy      = var.prevent_tf_log_deletion

  tags = {
    environment = var.env_name
  }
}

# TODO: rename this to ${var.env_name}/elasticache/redis
resource "aws_cloudwatch_log_group" "elasticache_redis_log" {
  name         = "elasticache-${var.env_name}-redis"
  skip_destroy = var.prevent_tf_log_deletion

  tags = {
    environment = var.env_name
  }
}
