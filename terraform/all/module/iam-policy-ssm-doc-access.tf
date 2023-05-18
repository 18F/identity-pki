# only allow ssm:StartSession if an SSM document is provided with --document-name
locals {
  ssm_document_access_arns = {
    for group, perms in var.ssm_document_access_map : group => flatten([
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

  ssm_command_access_arns = {
    for group, perms in var.ssm_command_access_map : group => flatten([
      for perm in perms : flatten([
        for pair in setproduct(keys(perm), flatten([values(perm)])) : join(
          "", [
            "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:document/",
            pair[0],
            "-ssm-cmd-",
            pair[1]
          ]
        )
      ])
    ])
  }

  ssm_access_arns = {
    for role in keys(local.ssm_document_access_arns) : role => concat(local.ssm_document_access_arns[role], local.ssm_command_access_arns[role])
  }
}

data "aws_iam_policy_document" "ssm_command_access" {
  for_each = local.ssm_access_arns

  statement {
    sid    = "${each.key}SSMDocAccess"
    effect = "Allow"
    actions = [
      "ssm:StartSession",
      "ssm:SendCommand",
      "ssm:TerminateSession",
    ]
    resources = [for arn in each.value : arn]
    condition {
      test     = "BoolIfExists"
      variable = "ssm:SessionDocumentAccessCheck"
      values = [
        "true",
      ]
    }
  }

  statement {
    sid    = "${each.key}SSMCmdInvocation"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
    ]
    resources = [
      join(":", [
        "arn:aws:ssm:${var.region}",
        "${data.aws_caller_identity.current.account_id}",
        "*"]
      )
    ]
    condition {
      test     = "BoolIfExists"
      variable = "ssm:SessionDocumentAccessCheck"
      values = [
        "true",
      ]
    }
  }


  statement {
    sid    = "${each.key}SSMCmdAccess"
    effect = "Allow"
    actions = [
      "ssm:StartSession",
      "ssm:SendCommand",
      "ssm:TerminateSession",
    ]
    resources = [
      join(":", [
        "arn:aws:ec2:${var.region}",
        "${data.aws_caller_identity.current.account_id}",
        "instance/*"]
      )
    ]
    condition {
      test     = "BoolIfExists"
      variable = "ssm:SessionDocumentAccessCheck"
      values = [
        "true",
      ]
    }
    condition {
      # only allow specific commands on specific instance types
      # in specific environment(s), as mapped out in local.ssm_cmd_map
      test     = "StringLike"
      variable = "aws:ResourceTag/Name"
      values = distinct(flatten([
        for env in flatten([
          for arn in each.value : element(split(
            "-", element(split("/", arn), 1)
          ), 0)
          ]) : formatlist(
          "asg-%s-%s", env, flatten([
            for cmd in distinct([
              for arn in each.value : replace(arn, "/.+ssm-document-/", "")
            ]) : lookup(local.ssm_cmd_map, cmd, "*")
          ])
        )
      ]))
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

### TODO: set this up and figure out enforcement in a future PR
## deny any roles not within ssm_access_arns
#data "aws_iam_policy_document" "ssm_nondoc_deny" {
#  statement {
#    sid    = "SSMNonDocDeny"
#    effect = "Deny"
#    actions = [
#      "ssm:StartSession",
#    ]
#    resources = ["*"]
#  }
#}
