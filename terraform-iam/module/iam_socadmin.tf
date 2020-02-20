data "aws_iam_policy_document" "socadmin" {
  count = var.iam_socadmin_enabled ? 1 : 0

  statement {
    sid    = "SOCAdministrator"
    effect = "Allow"
    actions = [
      "access-analyzer:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "logs:*",
      "config:*",
      "guardduty:*",
      "iam:Get*",
      "iam:List*",
      "iam:Generate*",
      "inspector:*",
      "macie:*",
      "organizations:List*",
      "organizations:Describe*",
      "s3:HeadBucket",
      "s3:List*",
      "s3:Get*",
      "securityhub:*",
      "shield:*",
      "ssm:*",
      "trustedadvisor:*",
      "waf:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "socadmin" {
  count = var.iam_socadmin_enabled ? 1 : 0

  name                 = "SOCAdministrator"
  assume_role_policy   = data.aws_iam_policy_document.master_account_assumerole.json
  path                 = "/"
  max_session_duration = 43200 #seconds
}

resource "aws_iam_policy" "socadmin" {
  count = var.iam_socadmin_enabled ? 1 : 0

  name        = "SOCAdministrator"
  path        = "/"
  description = "Policy for SOC administrators"
  policy      = data.aws_iam_policy_document.socadmin[0].json
}

resource "aws_iam_role_policy_attachment" "socadmin" {
  count = var.iam_socadmin_enabled ? 1 : 0

  role       = aws_iam_role.socadmin[0].name
  policy_arn = aws_iam_policy.socadmin[0].arn
}

resource "aws_iam_role_policy_attachment" "socadmin_rds_delete_prevent" {
  count = var.iam_socadmin_enabled ? 1 : 0

  role       = aws_iam_role.socadmin[0].name
  policy_arn = aws_iam_policy.rds_delete_prevent.arn
}

resource "aws_iam_role_policy_attachment" "socadmin_region_restriction" {
  count = var.iam_socadmin_enabled ? 1 : 0

  role       = aws_iam_role.socadmin[0].name
  policy_arn = aws_iam_policy.region_restriction.arn
}
