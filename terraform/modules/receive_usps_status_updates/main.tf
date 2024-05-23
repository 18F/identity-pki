/*
 * # receive_usps_status_updates module
 *
 * This module creates the necessary infrastructure in AWS SES to receive notifications from USPS regarding individual user status updates for in-person-proofing
 *
 * ```hcl
 * module "receive_usps_status_updates" {
 *  usps_envs = ["foo_env","bar_env"]
 *  domain = "example.root.domain"
 * }
 * ```
 */

data "aws_sns_topic" "usps_topics" {
  count = length(var.usps_envs)

  name = "usps-${var.usps_envs[count.index]}-topic"
}

resource "aws_ses_receipt_rule" "usps_per_env" {
  count = length(var.usps_envs)

  name          = "usps-${var.usps_envs[count.index]}-rule"
  rule_set_name = var.rule_set_name
  recipients    = ["registration@usps.${var.usps_envs[count.index]}.${var.domain}"]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Require"
  # after = count.index == 0 ? "drop-no-reply" : aws_ses_receipt_rule.usps_per_env[count.index - 1].name

  sns_action {
    topic_arn = data.aws_sns_topic.usps_topics[count.index].arn
    position  = 1
  }

  stop_action {
    position = 2
    scope    = "RuleSet"
  }
}

resource "aws_ses_receipt_filter" "filter_allow_usps" {
  for_each = toset(var.usps_ip_addresses)
  name     = "allow_usps_${split(".", each.key)[2]}"
  cidr     = each.key
  policy   = "Allow"
}
