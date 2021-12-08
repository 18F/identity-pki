locals {
  rule_settings = {
    override_action = var.enforce ? "none" : "count"
  }
}

data "aws_lb" "idp" {
  name = "login-idp-alb-${var.env}"
}

resource "aws_wafv2_web_acl" "idp" {
  name        = local.web_acl_name
  description = "ACL for ${local.web_acl_name}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "IdpBlockIpAddresses"
    priority = 0

    action {
      dynamic "block" {
        for_each = length(lookup(local.rule_settings, "override_action", {})) == 0 || lookup(local.rule_settings, "override_action", {}) == "none" ? [1] : []
        content {}
      }

      dynamic "count" {
        for_each = lookup(local.rule_settings, "override_action", {}) == "count" ? [1] : []
        content {}
      }
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.block_list.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-IdpBlockIpAddresses-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      dynamic "none" {
        for_each = length(lookup(local.rule_settings, "override_action", {})) == 0 || lookup(local.rule_settings, "override_action", {}) == "none" ? [1] : []
        content {}
      }

      dynamic "count" {
        for_each = lookup(local.rule_settings, "override_action", {}) == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"

        dynamic "excluded_rule" {
          for_each = var.ip_reputation_ruleset_exclusions

          content {
            name = excluded_rule.value
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-AWSManagedRulesAmazonIpReputationList-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      dynamic "none" {
        for_each = length(lookup(local.rule_settings, "override_action", {})) == 0 || lookup(local.rule_settings, "override_action", {}) == "none" ? [1] : []
        content {}
      }

      dynamic "count" {
        for_each = lookup(local.rule_settings, "override_action", {}) == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        dynamic "excluded_rule" {
          for_each = var.common_ruleset_exclusions

          content {
            name = excluded_rule.value
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-AWSManagedRulesCommonRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      dynamic "none" {
        for_each = length(lookup(local.rule_settings, "override_action", {})) == 0 || lookup(local.rule_settings, "override_action", {}) == "none" ? [1] : []
        content {}
      }

      dynamic "count" {
        for_each = lookup(local.rule_settings, "override_action", {}) == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"

        dynamic "excluded_rule" {
          for_each = var.known_bad_input_ruleset_exclusions

          content {
            name = excluded_rule.value
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-AWSManagedRulesKnownBadInputsRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 4

    override_action {
      dynamic "none" {
        for_each = length(lookup(local.rule_settings, "override_action", {})) == 0 || lookup(local.rule_settings, "override_action", {}) == "none" ? [1] : []
        content {}
      }

      dynamic "count" {
        for_each = lookup(local.rule_settings, "override_action", {}) == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"

        dynamic "excluded_rule" {
          for_each = var.linux_ruleset_exclusions

          content {
            name = excluded_rule.value
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-AWSManagedRulesLinuxRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 5

    override_action {
      dynamic "none" {
        for_each = length(lookup(local.rule_settings, "override_action", {})) == 0 || lookup(local.rule_settings, "override_action", {}) == "none" ? [1] : []
        content {}
      }

      dynamic "count" {
        for_each = lookup(local.rule_settings, "override_action", {}) == "count" ? [1] : []
        content {}
      }
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"

        dynamic "excluded_rule" {
          for_each = var.sql_injection_ruleset_exclusions

          content {
            name = excluded_rule.value
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-AWSManagedRulesSQLiRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "IdpOtpSendRateLimited"
    priority = 6

    action {
      dynamic "block" {
        for_each = length(lookup(local.rule_settings, "override_action", {})) == 0 || lookup(local.rule_settings, "override_action", {}) == "none" ? [1] : []
        content {}
      }

      dynamic "count" {
        for_each = lookup(local.rule_settings, "override_action", {}) == "count" ? [1] : []
        content {}
      }
    }

    statement {
      rate_based_statement {
        limit              = var.otp_send_rate_limit_per_ip
        aggregate_key_type = "IP"

        scope_down_statement {
          or_statement {
            statement {
              byte_match_statement {
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "CONTAINS"
                search_string         = "/otp/send"
                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
            statement {
              byte_match_statement {
                field_to_match {
                  uri_path {}
                }
                positional_constraint = "CONTAINS"
                search_string         = "/sign_up/verify_email"
                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-IdpOtpSendRateLimited-metric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.web_acl_name}-metric"
    sampled_requests_enabled   = true
  }

  tags = {
    environment = var.env
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "idp" {
  log_destination_configs = [
    aws_cloudwatch_log_group.cw_waf_logs.arn
  ]
  resource_arn = aws_wafv2_web_acl.idp.arn
}

resource "aws_wafv2_web_acl_association" "idp" {
  resource_arn = data.aws_lb.idp.arn
  web_acl_arn  = aws_wafv2_web_acl.idp.arn
}

resource "aws_cloudwatch_metric_alarm" "wafv2_blocked_alert" {
  alarm_name          = "${var.env}-wafv2-blocks-exceeded"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = var.waf_alert_blocked_period
  statistic           = "Sum"
  threshold           = var.waf_alert_blocked_threshold
  alarm_description   = "More than ${var.waf_alert_blocked_threshold} WAF blocks occured in ${var.waf_alert_blocked_period} seconds"
  alarm_actions       = var.waf_alert_actions
  dimensions = {
    Rule   = "ALL"
    Region = var.region
    WebACL = "${var.env}-idp-waf"
  }
}
