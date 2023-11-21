# This terraform module contains inbound SES email configuration used
resource "aws_ses_receipt_rule" "admin-at" {
  count = var.enabled

  name          = "admin-at-store"
  rule_set_name = var.rule_set_name
  recipients    = ["admin@${var.domain}"]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Require"

  s3_action {
    bucket_name       = var.email_bucket
    object_key_prefix = "${var.email_bucket_prefix}admin-at/"
    position          = 1
  }

  sns_action {
    position  = 2
    topic_arn = aws_sns_topic.admin-at[0].arn
  }

  stop_action {
    position = 3
    scope    = "RuleSet"
  }
}

# you have to subscribe to this topic manually since aws_sns_topic_subscription
# doesn't support the email protocol
resource "aws_sns_topic" "admin-at" {
  count = var.enabled

  name = "email_admin-at-identitysandbox-dot-gov"
}

resource "aws_ses_receipt_rule" "drop-no-reply" {
  count = var.enabled

  name          = "drop-no-reply"
  rule_set_name = var.rule_set_name
  after         = aws_ses_receipt_rule.admin-at[count.index].name
  recipients    = ["no-reply@${var.domain}"]
  enabled       = true
  scan_enabled  = true

  stop_action {
    position = 1
    scope    = "RuleSet"
  }
}

data "aws_sns_topic" "usps_topics" {
  count = var.enabled == 1 ? length(var.usps_envs) : 0

  name = "usps-${var.usps_envs[count.index]}-topic"
}

resource "aws_ses_receipt_rule" "usps_per_env" {
  count = var.enabled == 1 ? length(var.usps_envs) : 0

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


resource "aws_ses_receipt_rule" "email_users" {
  for_each = {
    for user in var.email_users : user => "${user}@${var.domain}"
  }

  name          = "${each.key}-at-store"
  rule_set_name = var.rule_set_name
  recipients    = [each.value]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Require"

  s3_action {
    bucket_name       = var.email_bucket
    object_key_prefix = "${var.email_bucket_prefix}${each.key}/"
    position          = 1
  }
  stop_action {
    position = 2
    scope    = "RuleSet"
  }
}

resource "aws_ses_receipt_rule" "bounce-unknown" {
  count = var.enabled

  name          = "bounce-unknown_mailboxes"
  rule_set_name = var.rule_set_name
  after         = length(var.usps_envs) > 0 ? aws_ses_receipt_rule.usps_per_env[length(var.usps_envs) - 1].name : aws_ses_receipt_rule.drop-no-reply[count.index].name

  # no recipients, so this is a catchall

  enabled      = true
  scan_enabled = true

  bounce_action {
    position        = 1
    message         = "Mailbox does not exist"
    sender          = "no-reply@${var.domain}"
    smtp_reply_code = "550"
    status_code     = "5.1.1"
  }
}

resource "aws_ses_receipt_filter" "filter-allow-usps" {
  for_each = toset(var.usps_ip_addresses)
  name     = "allow_usps_${split(".", each.key)[2]}"
  cidr     = each.key
  policy   = "Allow"
}

# these rules are applied in the order they appear, so
# the full block list is last - anything not in the 
# above allow lists will be blocked. Uncertain if order
# is preserved
resource "aws_ses_receipt_filter" "filter-block" {
  name   = "block_ips"
  cidr   = "0.0.0.0/0"
  policy = "Block"
}
