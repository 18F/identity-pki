locals {
  tf_acct      = trimprefix(data.aws_iam_account_alias.current.account_alias, "login-")
  web_acl_name = var.lb_name != "" ? "${var.lb_name}-waf" : "${var.env}-${var.app}-waf"
  rule_settings = {
    override_action = var.enforce ? "none" : "count"
  }
}

resource "aws_wafv2_web_acl" "alb" {
  name        = local.web_acl_name
  description = "ACL for ${local.web_acl_name}"
  scope       = var.wafv2_web_acl_scope

  default_action {
    allow {}
  }

  # This rule is temporarily placed before the others to COUNT traffic from bots.
  # Its priority may be changed later.
  dynamic "rule" {
    for_each = var.wafv2_web_acl_scope == "CLOUDFRONT" && length(var.bot_control_exclusions) > 1 ? [1] : []
    content {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = 20

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"

          dynamic "rule_action_override" {
            for_each = toset(var.bot_control_exclusions)

            content {
              action_to_use {
                count {
                  # Terraform AWS provider has a bug, using workaround as suggested here:
                  # https://github.com/hashicorp/terraform-provider-aws/issues/28191#issuecomment-1398853194
                  custom_request_handling {
                    insert_header {
                      name  = "TFWorkaround"
                      value = "WAF"
                    }
                  }
                }
              }
              name = rule_action_override.value
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-AWSManagedRulesBotControlRuleSet-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  # Only these first 2 rules have the 'allow' action, short-circuiting the other rules.
  dynamic "rule" {
    for_each = length(data.aws_wafv2_ip_set.acl["privileged_ips_v4"]) > 0 ? [1] : []
    content {
      name     = "AllowPrivilegedIPs"
      priority = 50
      action {
        allow {}
      }
      statement {
        or_statement {
          # Support matching in case of direct access or through CDN
          statement {
            ip_set_reference_statement {
              arn = data.aws_wafv2_ip_set.acl["privileged_ips_v4"].arn
            }
          }
          dynamic "statement" {
            for_each = length(data.aws_wafv2_ip_set.acl["privileged_ips_v6"]) > 0 ? [1] : []
            content {
              ip_set_reference_statement {
                arn = data.aws_wafv2_ip_set.acl["privileged_ips_v6"].arn
              }
            }
          }
          statement {
            ip_set_reference_statement {
              arn = data.aws_wafv2_ip_set.acl["privileged_ips_v4"].arn
              ip_set_forwarded_ip_config {
                header_name       = "X-Forwarded-For"
                position          = "FIRST"
                fallback_behavior = "NO_MATCH"
              }
            }
          }
          dynamic "statement" {
            for_each = length(data.aws_wafv2_ip_set.acl["privileged_ips_v6"]) > 0 ? [1] : []
            content {
              ip_set_reference_statement {
                arn = data.aws_wafv2_ip_set.acl["privileged_ips_v6"].arn
                ip_set_forwarded_ip_config {
                  header_name       = "X-Forwarded-For"
                  position          = "FIRST"
                  fallback_behavior = "NO_MATCH"
                }
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-PrivilegedIPs-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = length(data.aws_wafv2_regex_pattern_set.app["restricted_paths"]) > 0 ? [1] : []
    content {
      name     = "IdpBlockPaths"
      priority = 55
      action {
        dynamic "block" {
          for_each = var.restricted_paths_enforce ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = var.restricted_paths_enforce ? [] : [1]
          content {}
        }
      }
      statement {
        dynamic "and_statement" {
          # Only combine the resticted path AND the exclusion path patterns
          # if both are present
          # MUST match same variable in terraform/core or terraform/gitlab!
          for_each = length(var.restricted_paths.exclusions) > 0 ? [1] : []
          content {
            statement {
              not_statement {
                statement {
                  regex_pattern_set_reference_statement {
                    arn = data.aws_wafv2_regex_pattern_set.app["restricted_paths_exclusions"].arn
                    field_to_match {
                      uri_path {}
                    }
                    text_transformation {
                      priority = 0
                      type     = "LOWERCASE"
                    }
                  }
                }
              }
            }
            statement {
              regex_pattern_set_reference_statement {
                arn = data.aws_wafv2_regex_pattern_set.app["restricted_paths"].arn
                field_to_match {
                  uri_path {}
                }
                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }
        dynamic "regex_pattern_set_reference_statement" {
          # No AND needed if only a restricted path pattern is set
          # MUST match same variable in terraform/core or terraform/gitlab!
          for_each = length(var.restricted_paths.exclusions) > 0 ? [] : [1]
          content {
            arn = data.aws_wafv2_regex_pattern_set.app["restricted_paths"].arn
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.env}-restricted-paths-BlockPaths-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "AllowTrafficToPaths"
    priority = 60

    action {
      allow {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = data.aws_wafv2_regex_pattern_set.acct["limit_exempt_paths"].arn

        field_to_match {
          uri_path {}
        }

        text_transformation {
          priority = 2
          type     = "LOWERCASE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.web_acl_name}-AllowTrafficToPaths-metric"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = length(data.aws_wafv2_ip_set.acl["block_list_v4"].arn) > 0 ? [1] : []
    content {
      name     = "IdpBlockIpAddresses"
      priority = 100
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
        or_statement {
          # Support matching in case of direct access or through CDN
          statement {
            ip_set_reference_statement {
              arn = data.aws_wafv2_ip_set.acl["block_list_v4"].arn
            }
          }
          dynamic "statement" {
            for_each = length(data.aws_wafv2_ip_set.acl["block_list_v6"]) > 0 ? [1] : []
            content {
              ip_set_reference_statement {
                arn = data.aws_wafv2_ip_set.acl["block_list_v6"].arn
              }
            }
          }
          statement {
            ip_set_reference_statement {
              arn = data.aws_wafv2_ip_set.acl["block_list_v4"].arn
              ip_set_forwarded_ip_config {
                header_name       = "X-Forwarded-For"
                position          = "FIRST"
                fallback_behavior = "NO_MATCH"
              }
            }
          }
          dynamic "statement" {
            for_each = length(data.aws_wafv2_ip_set.acl["block_list_v6"]) > 0 ? [1] : []
            content {
              ip_set_reference_statement {
                arn = data.aws_wafv2_ip_set.acl["block_list_v6"].arn
                ip_set_forwarded_ip_config {
                  header_name       = "X-Forwarded-For"
                  position          = "FIRST"
                  fallback_behavior = "NO_MATCH"
                }
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-IdpBlockIpAddresses-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 200

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

        dynamic "rule_action_override" {
          for_each = var.ip_reputation_ruleset_exclusions

          content {
            action_to_use {
              count {
                # Terraform AWS provider has a bug, using workaround as suggested here:
                # https://github.com/hashicorp/terraform-provider-aws/issues/28191#issuecomment-1398853194
                custom_request_handling {
                  insert_header {
                    name  = "TFWorkaround"
                    value = "WAF"
                  }
                }
              }
            }
            name = rule_action_override.value
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
    priority = 300

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

        dynamic "rule_action_override" {
          for_each = var.common_ruleset_exclusions

          content {
            action_to_use {
              count {
                # Terraform AWS provider has a bug, using workaround as suggested here:
                # https://github.com/hashicorp/terraform-provider-aws/issues/28191#issuecomment-1398853194
                custom_request_handling {
                  insert_header {
                    name  = "TFWorkaround"
                    value = "WAF"
                  }
                }
              }
            }
            name = rule_action_override.value
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
    priority = 400

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

        dynamic "rule_action_override" {
          for_each = var.known_bad_input_ruleset_exclusions

          content {
            action_to_use {
              count {
                # Terraform AWS provider has a bug, using workaround as suggested here:
                # https://github.com/hashicorp/terraform-provider-aws/issues/28191#issuecomment-1398853194
                custom_request_handling {
                  insert_header {
                    name  = "TFWorkaround"
                    value = "WAF"
                  }
                }
              }
            }
            name = rule_action_override.value
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
    priority = 500

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

        dynamic "rule_action_override" {
          for_each = var.linux_ruleset_exclusions

          content {
            action_to_use {
              count {
                # Terraform AWS provider has a bug, using workaround as suggested here:
                # https://github.com/hashicorp/terraform-provider-aws/issues/28191#issuecomment-1398853194
                custom_request_handling {
                  insert_header {
                    name  = "TFWorkaround"
                    value = "WAF"
                  }
                }
              }
            }
            name = rule_action_override.value
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
    priority = 600

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

        # Exclude relaxed_uri_paths
        scope_down_statement {
          not_statement {
            statement {
              regex_pattern_set_reference_statement {
                arn = data.aws_wafv2_regex_pattern_set.acct["relaxed_uri_paths"].arn

                field_to_match {
                  uri_path {}
                }

                text_transformation {
                  priority = 0
                  type     = "LOWERCASE"
                }
              }
            }
          }
        }

        dynamic "rule_action_override" {
          for_each = var.sql_injection_ruleset_exclusions

          content {
            action_to_use {
              count {
                # Terraform AWS provider has a bug, using workaround as suggested here:
                # https://github.com/hashicorp/terraform-provider-aws/issues/28191#issuecomment-1398853194
                custom_request_handling {
                  insert_header {
                    name  = "TFWorkaround"
                    value = "WAF"
                  }
                }
              }
            }
            name = rule_action_override.value
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
    priority = 700

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

  dynamic "rule" {
    # MUST match var.header_block_regex in terraform/core or terraform/gitlab!
    for_each = length(var.header_block_regex) >= 1 ? [1] : []
    content {
      name     = "IdpHeaderRegexBlock"
      priority = 800

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
        or_statement {
          dynamic "statement" {
            for_each = var.header_block_regex
            content {
              regex_pattern_set_reference_statement {
                arn = data.aws_wafv2_regex_pattern_set.header_blocks[statement.key].arn

                field_to_match {
                  single_header {
                    name = lower(statement.value.field_name)
                  }
                }
                text_transformation {
                  priority = 2
                  type     = "NONE"
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-HeaderBlock-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    # MUST match var.query_block_regex in terraform/core or terraform/gitlab!
    for_each = length(var.query_block_regex) >= 1 ? [1] : []
    content {
      name     = "IdpQueryRegexBlock"
      priority = 900

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
        regex_pattern_set_reference_statement {
          arn = data.aws_wafv2_regex_pattern_set.app["query_string_blocks"].arn

          text_transformation {
            priority = 2
            type     = "NONE"
          }

          field_to_match {
            query_string {}
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-QueryStringBlock-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.geo_block_list) >= 1 ? [1] : []
    content {
      name     = "GeoBlockRegion"
      priority = 1000

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
        geo_match_statement {
          country_codes = var.geo_block_list
        }
      }


      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-GeoBlockRegion-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = length(var.geo_allow_list) >= 1 ? [1] : []
    content {
      name     = "GeoAllowRegion"
      priority = 1200

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            geo_match_statement {
              country_codes = var.geo_allow_list
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-GeoAllowRegion-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.wafv2_web_acl_scope == "CLOUDFRONT" && var.enforce_rate_limit ? [1] : []
    content {
      name     = "RateLimitBlockRequestFromSourceIPs"
      priority = 1400

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-RateLimitBySourceIP-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.wafv2_web_acl_scope != "CLOUDFRONT" && var.enforce_rate_limit ? [1] : []
    content {
      name     = "RateLimitBlockRequestFromHeaderIPs"
      priority = 1500

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "FORWARDED_IP"

          forwarded_ip_config {
            fallback_behavior = "MATCH"
            header_name       = "X-Forwarded-For"
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-RateLimitByHeaderIP-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  # WIP not ready for prod deployment
  dynamic "rule" {
    for_each = var.enforce_waf_captcha == true ? [1] : []
    content {
      name     = "EnforceCaptcha"
      priority = 1500

      action {
        captcha {}
      }

      statement {
        and_statement {
          statement {
            byte_match_statement {
              field_to_match {
                uri_path {}
              }

              positional_constraint = "EXACTLY"
              search_string         = "/"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }

          statement {
            not_statement {
              statement {
                geo_match_statement {
                  country_codes = var.geo_us_regions
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-CaptchaEnabled-metric"
        sampled_requests_enabled   = true
      }
    }
  }

  # WIP not ready for prod deployment
  dynamic "rule" {
    for_each = var.enforce_waf_challenge == true ? [1] : []
    content {
      name     = "EnforceChallenge"
      priority = 1600

      action {
        challenge {}
      }

      statement {
        and_statement {
          statement {
            byte_match_statement {
              field_to_match {
                uri_path {}
              }

              positional_constraint = "EXACTLY"
              search_string         = "/"
              text_transformation {
                priority = 0
                type     = "NONE"
              }
            }
          }

          statement {
            not_statement {
              statement {
                geo_match_statement {
                  country_codes = var.geo_us_regions
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.web_acl_name}-ChallengeEnabled-metric"
        sampled_requests_enabled   = true
      }
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

  # hack to avoid trying to set tags_all for aws_wafv2_web_acl,
  # which does not currently (2022-07-26) work
  # for more details, see:
  # https://github.com/hashicorp/terraform-provider-aws/issues/23992
  # https://github.com/hashicorp/terraform-provider-aws/issues/24386
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "alb" {
  log_destination_configs = [
    aws_cloudwatch_log_group.cw_waf_logs.arn
  ]
  resource_arn = aws_wafv2_web_acl.alb.arn
}

resource "aws_wafv2_web_acl_association" "alb" {
  count        = var.wafv2_web_acl_scope == "REGIONAL" ? 1 : 0
  resource_arn = data.aws_lb.alb[count.index].arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}
