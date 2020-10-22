data "aws_lb" "idp" {
  name = "login-idp-alb-${var.env}"
}

module "waf-webaclv2" {
  # https://registry.terraform.io/modules/umotif-public/waf-webaclv2/aws/latest
  source  = "umotif-public/waf-webaclv2/aws"
  version = "1.5.0"

  name_prefix = local.name_prefix
  alb_arn     = data.aws_lb.idp.arn

  scope = "REGIONAL"

  create_alb_association = var.associate_alb

  allow_default_action = true

  visibility_config = {
    metric_name = "${local.name_prefix}-main-metrics"
  }

  create_logging_configuration = true
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]

  rules = [
    {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = "0"

      # set override_action to "none" to block
      override_action = var.waf_override

      visibility_config = {
        metric_name = "${local.name_prefix}-AWSManagedRulesAmazonIpReputationList-metric"
      }
      managed_rule_group_statement = {
        name          = "AWSManagedRulesAmazonIpReputationList"
        vendor_name   = "AWS"
        excluded_rule = []
      }
    },
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = "1"

      override_action = var.waf_override
      visibility_config = {
        metric_name = "${local.name_prefix}-AWSManagedRulesCommonRuleSet-metric"
      }

      managed_rule_group_statement = {
        name          = "AWSManagedRulesCommonRuleSet"
        vendor_name   = "AWS"
        excluded_rule = []
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = "2"

      override_action = var.waf_override

      visibility_config = {
        metric_name = "${local.name_prefix}-AWSManagedRulesKnownBadInputsRuleSet-metric"
      }
      managed_rule_group_statement = {
        name          = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name   = "AWS"
        excluded_rule = []
      }
    },
    {
      name     = "AWSManagedRulesLinuxRuleSet"
      priority = "3"

      override_action = var.waf_override

      visibility_config = {
        metric_name = "${local.name_prefix}-AWSManagedRulesLinuxRuleSet-metric"
      }
      managed_rule_group_statement = {
        name          = "AWSManagedRulesLinuxRuleSet"
        vendor_name   = "AWS"
        excluded_rule = []
      }
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = "4"

      override_action = var.waf_override

      visibility_config = {
        metric_name = "${local.name_prefix}-AWSManagedRulesSQLiRuleSet-metric"
      }
      managed_rule_group_statement = {
        name          = "AWSManagedRulesSQLiRuleSet"
        vendor_name   = "AWS"
        excluded_rule = []
      }
    }
  ]
}
