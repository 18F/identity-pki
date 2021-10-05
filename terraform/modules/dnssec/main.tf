# -- Data Sources --

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "ksk_policy" {
  statement {
    sid      = "Allow Route 53 DNSSEC Service",
    effect   = "Allow"
    actions  = [
      "kms:DescribeKey",
      "kms:GetPublicKey",
      "kms:Sign",
    ],
    principals {
      type        = "Service"
      identifiers = [
        "dnssec-route53.amazonaws.com"
      ]
    }
    resources = "*"
  },
  statement {
    sid     = "Allow Route 53 DNSSEC Service to CreateGrant",
    effect  = "Allow"
    actions = "kms:CreateGrant",
    principals {
      type        = "Service"
      identifiers = [
        "dnssec-route53.amazonaws.com"
      ]
    }
    resources = "*"
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = [
        "true",
      ]
    }
  },
  statement {
    sid      = "IAM User Permissions"
    effect   = "Allow"
    actions  = "kms:*"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = "*"
  }
}

resource "aws_kms_key" "dnssec_root_zone" {
  for_each = var.dnssec_ksks

  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy                   = data.aws_iam_policy_document.ksk_policy.json
}

resource "aws_kms_alias" "dnssec_root_zone" {
  for_each = var.dnssec_ksks

  name          = "alias/${replace(var.domain, "/\\./", "_")}-ksk-${each.key}"
  target_key_id = aws_kms_key.dnssec_root_zone[each.key].key_id
}

resource "aws_route53_key_signing_key" "root_zone" {
  for_each = var.dnssec_ksks

  hosted_zone_id             = var.root_zone_id
  key_management_service_arn = aws_kms_key.dnssec_root_zone[each.key].arn
  name                       = "${replace(var.domain, "/\\./", "_")}-ksk-${each.key}"
}

resource "aws_route53_hosted_zone_dnssec" "root_zone" {
  hosted_zone_id = var.root_zone_id
}

output "root_zone_dnssec_ksks" {
  description = "DNSSEC Key Signing Key information"

  value = tomap({
    for k, v in aws_route53_key_signing_key.root_zone : k => tomap({
      digest_algorithm  = v.digest_algorithm_mnemonic,
      digest_value      = v.digest_value,
      signing_algorithm = v.signing_algorithm_mnemonic,
      ds_record         = v.ds_record
    })
  })
}
