# This terraform module contains inbound SES email configuration used
resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = var.rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.main.id
}

resource "aws_ses_receipt_rule" "admin-at" {
  count = var.sandbox_features_enabled ? 1 : 0

  name          = "admin-at-store"
  rule_set_name = aws_ses_active_receipt_rule_set.main.id
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
  count = var.sandbox_features_enabled ? 1 : 0

  name = "email_admin-at-identitysandbox-dot-gov"
}

resource "aws_ses_receipt_rule" "drop-no-reply" {
  name          = "drop-no-reply"
  rule_set_name = aws_ses_active_receipt_rule_set.main.id
  after         = var.sandbox_features_enabled ? aws_ses_receipt_rule.admin-at[0].name : ""
  recipients    = ["no-reply@${var.domain}"]
  enabled       = true
  scan_enabled  = true

  stop_action {
    position = 1
    scope    = "RuleSet"
  }
}

module "receive_usps_status_updates" {
  source = "../receive_usps_status_updates/"
  count  = var.usps_features_enabled ? 1 : 0

  usps_envs         = var.usps_envs
  rule_set_name     = var.rule_set_name
  domain            = var.domain
  usps_ip_addresses = var.usps_ip_addresses

  depends_on = [aws_ses_active_receipt_rule_set.main]
}

resource "aws_ses_receipt_rule" "email_users" {
  for_each = var.sandbox_features_enabled ? {
    for user in var.email_users : user => "${user}@${var.domain}"
  } : {}

  name          = "${each.key}-at-store"
  rule_set_name = aws_ses_active_receipt_rule_set.main.id
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
  name          = "bounce-unknown_mailboxes"
  rule_set_name = aws_ses_active_receipt_rule_set.main.id
  after         = length(var.usps_envs) > 0 && var.usps_features_enabled ? module.receive_usps_status_updates[0].last_receipt_rule : aws_ses_receipt_rule.drop-no-reply.name

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

# these rules are applied in the order they appear, so
# the full block list is last - anything not in the 
# above allow lists will be blocked. Uncertain if order
# is preserved
resource "aws_ses_receipt_filter" "filter-block" {
  name   = "block_ips"
  cidr   = "0.0.0.0/0"
  policy = "Block"
}

moved {
  from = aws_sns_topic.usps_topics
  to   = module.receive_usps_status_updates[0].aws_sns_topic.usps_topics
}

moved {
  from = aws_ses_receipt_rule.usps_per_env
  to   = module.receive_usps_status_updates[0].aws_ses_receipt_rule.usps_per_env
}

moved {
  from = aws_ses_receipt_filter.filter-allow-usps
  to   = module.receive_usps_status_updates[0].aws_ses_receipt_filter.filter_allow_usps
}

moved {
  from = aws_ses_receipt_rule.drop-no-reply[0]
  to   = aws_ses_receipt_rule.drop-no-reply
}

moved {
  from = aws_ses_receipt_rule.bounce-unknown[0]
  to   = aws_ses_receipt_rule.bounce-unknown
}
