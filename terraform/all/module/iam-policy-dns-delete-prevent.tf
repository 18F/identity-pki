# prevent disabling of DNSSEC / deletion of top-level hosted zone; used by all roles

locals {
  dnssec_zone_exists = var.dnssec_zone_name == "" ? 0 : 1
}

data "aws_route53_zone" "dnssec_zone" {
  count = local.dnssec_zone_exists
  name  = var.dnssec_zone_name
}

data "aws_iam_policy_document" "dnssec_disable_prevent" {
  count = local.dnssec_zone_exists

  statement {
    sid    = "HostedZoneAndKSKDisableDeletePrevent"
    effect = "Deny"
    actions = [
      "route53:DeactivateKeySigningKey",
      "route53:DeleteHostedZone",
      "route53:DeleteKeySigningKey",
      "route53:DisableHostedZoneDNSSEC",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.dnssec_zone[0].id}"
    ]
  }

  statement {
    sid    = "KMSAliasDisableDeletePrevent"
    effect = "Deny"
    actions = [
      "kms:DeleteAlias",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.dnssec_zone[0].id}"
    ]
  }

  statement {
    sid    = "KMSKeyDisableDeletePrevent"
    effect = "Deny"
    actions = [
      "kms:DisableKey",
      "kms:ScheduleKeyDeletion",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.dnssec_zone[0].id}"
    ]
  }
}

resource "aws_iam_policy" "dnssec_disable_prevent" {
  count = local.dnssec_zone_exists

  name        = "DNSSecDisablePrevent"
  path        = "/"
  description = "Prevent disabling of DNSSEC / deletion of hosted zone ${var.dnssec_zone_name}"
  policy      = data.aws_iam_policy_document.dnssec_disable_prevent[0].json
}
