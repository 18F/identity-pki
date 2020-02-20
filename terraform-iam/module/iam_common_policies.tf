# allow assuming of roles from identity-master
data "aws_iam_policy_document" "master_account_assumerole" {
  statement {
    sid = "AssumeRoleFromMasterAccount"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.master_account_id}:root"
      ]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "true"
      ]
    }
  }
}

# restrict to west-2 and east-1; used by all roles
data "aws_iam_policy_document" "region_restriction" {
  statement {
    sid    = "RegionRestriction"
    effect = "Deny"
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values = [
        "us-west-2",
        "us-east-1",
      ]
    }
  }
}

resource "aws_iam_policy" "region_restriction" {
  name        = "RegionRestriction"
  path        = "/"
  description = "Limit region usage"
  policy      = data.aws_iam_policy_document.region_restriction.json
}

# prevent deletion of int/staging/prod RDS; used by all roles
data "aws_iam_policy_document" "rds_delete_prevent" {
  statement {
    sid    = "RDSDeletionPrevent"
    effect = "Deny"
    actions = [
      "rds:DeleteDBInstance",
    ]
    resources = [
      "arn:aws:rds:*:*:db:*int*",
      "arn:aws:rds:*:*:db:*staging*",
      "arn:aws:rds:*:*:db:*prod*",
    ]
  }
}

resource "aws_iam_policy" "rds_delete_prevent" {
  name        = "RDSDeletePrevent"
  path        = "/"
  description = "Prevent deletion of int, staging and prod rds instances"
  policy      = data.aws_iam_policy_document.rds_delete_prevent.json
}
