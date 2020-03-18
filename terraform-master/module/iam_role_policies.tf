resource "aws_iam_policy" "master_full_administrator" {
  name        = "MasterAssumeFullAdministator"
  path        = "/"
  description = "Policy to assign that permits user to assume full administrator role in master"
  policy      = data.aws_iam_policy_document.master_full_administrator.json
}

data "aws_iam_policy_document" "master_full_administrator" {
  statement {
    sid    = "MasterAssumeFullAdministratorWithMFA"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      aws_iam_role.master_full_administrator.arn,
    ]
  }
}

resource "aws_iam_policy" "master_socadministrator" {
  name        = "MasterAssumeSOCAdministrator"
  path        = "/"
  description = "Policy to assign that permits user to assume SOC Administrator in master"
  policy      = data.aws_iam_policy_document.master_socadministrator.json
}

data "aws_iam_policy_document" "master_socadministrator" {
  statement {
    sid    = "MasterAssumeSOCAdministrator"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      aws_iam_role.master_socadministrator.arn
    ]
  }
}

resource "aws_iam_policy" "master_billing_readonly" {
  name        = "MasterAssumeBillingReadOnly"
  path        = "/"
  description = "Policy to assign that permits user to assume Billing ReadOnly in master"
  policy      = data.aws_iam_policy_document.master_billing_readonly.json
}

data "aws_iam_policy_document" "master_billing_readonly" {
  statement {
    sid    = "MasterAssumeBillingReadOnly"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      aws_iam_role.master_billing_readonly.arn
    ]
  }
}
