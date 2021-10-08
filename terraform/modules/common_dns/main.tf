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

# -- Data Sources --

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "ksk_policy" {
  statement {
    sid      = "Allow Route 53 DNSSEC Service"
    effect   = "Allow"
    actions  = [
      "kms:DescribeKey",
      "kms:GetPublicKey",
      "kms:Sign",
    ]
    principals {
      type        = "Service"
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
      type        = "Service"
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
    sid      = "IAM User Permissions"
    effect   = "Allow"
    actions  = [
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

# -- Resources --

resource "aws_route53_zone" "primary" {
  # domain, ensuring it has a trailing "."
  name = replace(var.domain, "/\\.?$/", ".")
}

resource "aws_route53_record" "a" {
  for_each = {
    for a in local.cloudfront_aliases :
    a.name == "" ? "a_root" : "a_${trimsuffix(a.name, ".")}" => a
  }

  name    = join("", [each.value.name, var.domain])
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = each.value.alias_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "aaaa" {
  for_each = {
    for aaaa in local.cloudfront_aliases :
    aaaa.name == "" ? "aaaa_root" : "aaaa_${trimsuffix(aaaa.name, ".")}" => aaaa
  }

  name    = join("", [each.value.name, var.domain])
  type    = "AAAA"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = each.value.alias_name
    zone_id                = var.cloudfront_zone_id
  }
}

resource "aws_route53_record" "record" {
  for_each = { for n in flatten([
    for entry in flatten([local.records, var.prod_records]) : [
      for r in entry.record_set : {
        type    = entry.type,
        name    = r.name,
        ttl     = r.ttl,
        records = r.records
      }
    ]
  ]) : n.name == "" ? "${n.type}_main" : "${n.type}_${trimsuffix(n.name, ".")}" => n }

  name    = join("", [each.value.name, var.domain])
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
  zone_id = aws_route53_zone.primary.zone_id
}

resource "aws_route53_record" "acme_partners" {
  count   = var.domain == "login.gov" ? 1 : 0
  name    = "partners.${var.domain}"
  type    = "A"
  zone_id = aws_route53_zone.primary.zone_id
  alias {
    evaluate_target_health = false
    name                   = var.acme_partners_cloudfront_name
    zone_id                = var.cloudfront_zone_id
  }
}

##### DNSSEC #####
# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-troubleshoot.html

resource "aws_kms_key" "dnssec_primary" {
  for_each = var.dnssec_ksks
  provider = aws.use1

  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy                   = data.aws_iam_policy_document.ksk_policy.json
}

resource "aws_kms_alias" "dnssec_primary" {
  for_each = var.dnssec_ksks
  provider = aws.use1

  name          = "alias/${replace(var.domain, "/\\./", "_")}-ksk-${each.key}"
  target_key_id = aws_kms_key.dnssec_primary[each.key].key_id
}

resource "aws_route53_key_signing_key" "primary" {
  for_each = var.dnssec_ksks

  hosted_zone_id             = aws_route53_zone.primary.id
  key_management_service_arn = aws_kms_key.dnssec_primary[each.key].arn
  name                       = "${aws_route53_zone.primary.name}-ksk-${each.key}"
}

resource "aws_route53_hosted_zone_dnssec" "primary" {
  hosted_zone_id = aws_route53_zone.primary.id
}

resource "aws_cloudwatch_metric_alarm" "dnssec_ksks_action_req" {
  alarm_name        = "${aws_route53_zone.primary.name}-dnssec_ksks_action_req"
  alarm_description = "1+ DNSSEC KSKs require attention in <24h"
  namespace         = "AWS/Route53"
  metric_name       = "DNSSECKSKActionRequired"

  dimensions = {
    HostedZoneId = aws_route53_zone.primary.zone_id
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
  alarm_name        = "${aws_route53_zone.primary.name}-dnssec_ksk_age"
  alarm_description = "1+ DNSSEC KSKs are >${var.dnssec_ksk_max_days} days old"
  namespace         = "AWS/Route53"
  metric_name       = "DNSSECKSKAge"

  dimensions = {
    HostedZoneId = aws_route53_zone.primary.zone_id
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
  alarm_name        = "${aws_route53_zone.primary.name}-dnssec_errors"
  alarm_description = "DNSSEC encountered 1+ errors in <24h"
  namespace         = "AWS/Route53"
  metric_name       = "DNSSECErrors"

  dimensions = {
    HostedZoneId = aws_route53_zone.primary.zone_id
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 86400
  evaluation_periods  = 1
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
}
