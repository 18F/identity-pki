locals {
  waf_override = var.enforce ? "none" : "count"
}

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
  log_destination_configs      = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]

  rules = [
    {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = "0"

      # set override_action to "none" to block
      override_action = local.waf_override

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

      override_action = local.waf_override
      visibility_config = {
        metric_name = "${local.name_prefix}-AWSManagedRulesCommonRuleSet-metric"
      }

      managed_rule_group_statement = {
        name          = "AWSManagedRulesCommonRuleSet"
        vendor_name   = "AWS"
        excluded_rule = [
          # AWS description: "Inspects the values of the request body and blocks requests attempting to 
          # exploit RFI (Remote File Inclusion) in web applications. Examples include patterns like ://."
          "GenericRFI_BODY",
          # AWS description: "Inspects the values of all query parameters and blocks requests attempting to 
          # exploit RFI (Remote File Inclusion) in web applications. Examples include patterns like ://."
          "GenericRFI_QUERYARGUMENTS",
          # AWS description: "Verifies that the URI query string length is within the standard boundary for applications."
          "SizeRestrictions_QUERYSTRING",
          # AWS description: "Inspects for attempts to exfiltrate Amazon EC2 metadata from the request query arguments."
          "EC2MetaDataSSRF_QUERYARGUMENTS",
          # AWS description: "Inspects for attempts to exfiltrate Amazon EC2 metadata from the request cookie."
          "EC2MetaDataSSRF_BODY",
          # AWS description: "Blocks requests with no HTTP User-Agent header."
          "NoUserAgent_HEADER"
        ]
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = "2"

      override_action = local.waf_override

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

      override_action = local.waf_override

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

      override_action = local.waf_override

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
