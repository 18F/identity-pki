# prevent deletion of int/staging/prod RDS; used by all roles
locals {
  ssm_access_arns = {
    for group, perms in var.ssm_access_map : group => flatten([
      for perm in perms : flatten([
        for pair in setproduct(keys(perm), flatten([values(perm)])) : join(
          "", [
            "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:document/",
            pair[0],
            "-ssm-document-",
            pair[1]
          ]
        )
      ])
    ])
  }
}

data "aws_iam_policy_document" "ssm_command_access" {
  for_each = local.ssm_access_arns

  statement {
    sid    = "${each.key}SSMDocAccess"
    effect = "Allow"
    actions = [
      "ssm:StartSession",
    ]
    resources = flatten([
      "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
      [for arn in each.value : arn]
    ])
    condition {
      test     = "BoolIfExists"
      variable = "ssm:SessionDocumentAccessCheck"
      values = [
        "true",
      ]
    }
  }
  statement {
    sid    = "${each.key}SSMInstanceAccess"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeVpcs",
      "kms:GenerateDataKey",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "ssm_command_access" {
  for_each = local.ssm_access_arns

  name   = "${each.key}SSMDocAccess"
  role   = each.key
  policy = data.aws_iam_policy_document.ssm_command_access[each.key].json
}
