module "socadmin-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=99eb230e7ecf64838d4eef07f730bc552d15723a"

  role_name                = "SOCAdministrator"
  enabled                  = var.iam_socadmin_enabled
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "SOCAdministrator"
      policy_description = "Policy for SOC administrators"
      policy_document    = [
        {
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
        },
      ]
    }
  ]
}
