# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-troubleshoot.html

# -- Data Sources --

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "ksk_policy" {
  statement {
    sid     = "Allow Route 53 DNSSEC Service"
    effect  = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:GetPublicKey",
      "kms:Sign",
    ]
    principals {
      type = "Service"
      identifiers = [
        "dnssec-route53.amazonaws.com"
      ]
    }
    resources = [
      "*"
    ]
  }
  statement {
    sid     = "Allow Route 53 DNSSEC Service to CreateGrant"
    effect  = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    principals {
      type = "Service"
      identifiers = [
        "dnssec-route53.amazonaws.com"
      ]
    }
    resources = [
      "*"
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = [
        "true",
      ]
    }
  }
  statement {
    sid     = "IAM User Permissions"
    effect  = "Allow"
    actions = [
      "kms:*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = [
      "*"
    ]
  }
}

# -- Providers

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.usw2,
        aws.use1
      ]
    }
  }
}

resource "aws_kms_key" "dnssec" {
  for_each = var.dnssec_ksks
  provider = aws.use1

  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy                   = data.aws_iam_policy_document.ksk_policy.json
}

resource "aws_kms_alias" "dnssec" {
  for_each = var.dnssec_ksks
  provider = aws.use1

  name          = "alias/${replace(var.dnssec_zone_name, "/\\./", "_")}-ksk-${each.key}"
  target_key_id = aws_kms_key.dnssec[each.key].key_id
}

resource "aws_route53_key_signing_key" "dnssec" {
  for_each = var.dnssec_ksks

  hosted_zone_id             = var.dnssec_zone_id
  key_management_service_arn = aws_kms_key.dnssec[each.key].arn
  name                       = "${var.dnssec_zone_name}-ksk-${each.key}"
}

resource "aws_route53_hosted_zone_dnssec" "dnssec" {
  hosted_zone_id = var.dnssec_zone_id
}

resource "aws_cloudwatch_metric_alarm" "dnssec_ksks_action_req" {
  alarm_name        = "${var.dnssec_zone_name}-dnssec_ksks_action_req"
  alarm_description = "1+ DNSSEC KSKs require attention in <24h - https://github.com/18F/identity-devops/wiki/Runbook:-DNS#dnssec_ksks_action_req"
  namespace         = "AWS/Route53"
  metric_name       = "DNSSECKSKActionRequired"

  dimensions = {
    HostedZoneId = var.dnssec_zone_id
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 86400
  evaluation_periods  = 1

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "dnssec_ksk_age" {
  alarm_name        = "${var.dnssec_zone_name}-dnssec_ksk_age"
  alarm_description = "1+ DNSSEC KSKs are >${var.dnssec_ksk_max_days} days old - https://github.com/18F/identity-devops/wiki/Runbook:-DNS#dnssec_ksk_age"
  namespace         = "AWS/Route53"
  metric_name       = "DNSSECKSKAge"

  dimensions = {
    HostedZoneId = var.dnssec_zone_id
  }

  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.dnssec_ksk_max_days * 24 * 60 * 60
  period              = 86400
  evaluation_periods  = 1
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "dnssec_errors" {
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-troubleshoot.html
  alarm_name        = "${var.dnssec_zone_name}-dnssec_errors"
  alarm_description = "DNSSEC encountered 1+ errors in <24h - https://github.com/18F/identity-devops/wiki/Runbook:-DNS#dnssec_errors"
  namespace         = "AWS/Route53"
  metric_name       = "DNSSECErrors"

  dimensions = {
    HostedZoneId = var.dnssec_zone_id
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 86400
  evaluation_periods  = 1
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
}
