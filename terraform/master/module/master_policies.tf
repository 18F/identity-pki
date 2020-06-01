#### Master "FullAdministrator" policy that requires mfa device
resource "aws_iam_policy" "full_administrator" {
  name        = "FullAdministratorWithMFA"
  path        = "/"
  description = "Policy for full administrator with MFA"
  policy      = data.aws_iam_policy_document.full_administrator.json
}

data "aws_iam_policy_document" "full_administrator" {
  statement {
    sid    = "FullAdministratorWithMFA"
    effect = "Allow"
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
  }
}

#### Master "SOCAdministrator" policy
resource "aws_iam_policy" "socadministrator" {
  name        = "SOCAdministrator"
  path        = "/"
  description = "Policy for SOC administrators"
  policy      = data.aws_iam_policy_document.socadministrator.json
}

data "aws_iam_policy_document" "socadministrator" {
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
      "macie:*",
      "organizations:List*",
      "organizations:Describe*",
      "s3:HeadBucket",
      "s3:List*",
      "s3:Get*",
      "securityhub:*",
      "shield:*",
      "sns:*",
      "ssm:*",
      "trustedadvisor:*",
    ]
    resources = [
      "*"
    ]
  }
}

#### Master "BillingReadOnly" policy
resource "aws_iam_policy" "billing_readonly" {
  name        = "BillingReadOnly"
  path        = "/"
  description = "Policy for reporting group read-only access to Billing ui"
  policy      = data.aws_iam_policy_document.billing_readonly.json
}

data "aws_iam_policy_document" "billing_readonly" {
  statement {
    sid    = "BillingReadOnly"
    effect = "Allow"
    actions = [
      "aws-portal:ViewBilling",
    ]
    resources = [
      "*"
    ]
  }
}
