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
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=0aeb1065291b8fa0bb19f386cf4954147f075a81"

  role_name = "Auditor"
  enabled   = length(var.auditor_accounts) > 0

  iam_policies             = []
  master_assumerole_policy = data.aws_iam_policy_document.assume_auditor_role_policy.json
  # Using the AWS managed IAM policy SecurityAudit
  custom_policy_arns = ["arn:aws:iam::aws:policy/SecurityAudit"]
}
