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
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=995040426241ec92a1eccb391d32574ad5fc41be"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name        = "Auditor"
  enabled          = length(var.auditor_accounts) > 0
  role_description = "Allows auditors to have access to various AWS resources."

  iam_policies             = []
  master_assumerole_policy = data.aws_iam_policy_document.assume_auditor_role_policy.json
  # Using the AWS managed IAM policy SecurityAudit
  custom_iam_policies = ["SecurityAudit"]
}
