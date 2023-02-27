# Define policy documents for accounts that can assume this role
data "aws_iam_policy_document" "assume_auditor_role_policy" {
  dynamic "statement" {
    for_each = var.auditor_accounts
    content {
      sid = "AssumeAuditorRoleFrom${title(statement.key)}"
      actions = [
        "sts:AssumeRole"
      ]
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${statement.value}:root"
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
}

module "auditor-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name = "Auditor"
  enabled   = length(var.auditor_accounts) > 0

  iam_policies                    = []
  master_assumerole_policy        = data.aws_iam_policy_document.assume_auditor_role_policy.json
  permissions_boundary_policy_arn = var.permission_boundary_policy_name != "" ? data.aws_iam_policy.permission_boundary_policy[0].arn : ""
  # Using the AWS managed IAM policy SecurityAudit
  custom_policy_arns = ["arn:aws:iam::aws:policy/SecurityAudit"]
}
