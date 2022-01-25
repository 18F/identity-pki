resource "aws_cloudwatch_log_group" "squid_access_log" {
  name_prefix = "${var.env_name}_/var/log/squid/access.log"

  tags = {
    environment = var.env_name
  }
}

# This module creates cloudwatch logs filters that create metrics for squid
# total requests and denied requests. It also creates an alarm on denied
# creates alarm on total requests following below a threshold
# requests that notifies to the specified alarm SNS ARN.
module "outboundproxy_cloudwatch_filters" {
  source                  = "github.com/18F/identity-terraform//squid_cloudwatch_filters?ref=7e11ebe24e3a9cbc34d1413cf4d20b3d71390d5b"
  depends_on              = [aws_cloudwatch_log_group.squid_access_log]
  log_group_name_override = aws_cloudwatch_log_group.squid_access_log.name

  env_name      = var.env_name
  alarm_actions = [var.slack_events_sns_hook_arn] # notify slack on denied requests
}
