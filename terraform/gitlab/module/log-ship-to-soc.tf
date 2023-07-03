# For new AWS accounts you MUST contact the SOCaaS team to allow this account
# permission to the destination ARN.
# See: https://github.com/18F/identity-devops/wiki/Runbook:-GSA-SOC-as-a-Service-(SOCaaS)#cloudwatch-shipping-important-note
module "log-ship-to-soc-gitlab-logs" {
  count                               = var.send_cw_to_soc
  source                              = "../../modules/log_ship_to_soc"
  region                              = var.region
  cloudwatch_subscription_filter_name = "log-ship-to-soc"
  cloudwatch_log_group_name = {
    "${var.env_name}_all_gitlab_logs"                                   = ""
    "${var.env_name}_/var/log/gitlab/nginx/gitlab_access.log"           = ""
    "${var.env_name}_/var/log/gitlab/nginx/gitlab_error.log"            = ""
    "${var.env_name}_/var/log/gitlab/gitlab-rails/audit_json.log"       = ""
    "${var.env_name}_/var/log/gitlab/gitlab-rails/application_json.log" = ""
    "${var.env_name}_/var/log/gitlab/gitlab-rails/backup_json.log"      = ""
    "${var.env_name}_/var/log/gitlab/gitlab-shell/gitlab-shell.log"     = ""
    "${var.env_name}_/var/log/auth.log"                                 = ""
    "${var.env_name}_/var/log/audit/audit.log"                          = ""
    "${var.env_name}_/var/log/kern.log"                                 = ""
    "${var.env_name}_/var/log/messages"                                 = ""
    "${var.env_name}_/var/log/syslog"                                   = ""
  }
  env_name            = var.env_name
  soc_destination_arn = var.soc_destination_arn
}
