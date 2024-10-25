module "fraudops-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=995040426241ec92a1eccb391d32574ad5fc41be"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "FraudOps"
  enabled                         = contains(local.enabled_roles, "iam_fraudops_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = [
    {
      policy_name        = "FraudOpsReadSsmParameters"
      policy_description = "Allow FraudOps to read a subset of SSM Parameters"
      policy_document = [
        {
          sid    = "ReadSsmParameters"
          effect = "Allow"
          actions = [
            "ssm:GetParameter"
          ]
          resources = [
            "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/account/salesforce/*"
          ]
        }
      ]
    },
    {
      policy_name        = "FraudOpsCloudwatchLogsQuery"
      policy_description = "Allow FraudOps query a subset of Cloudwatch Logs, used by bin/query-cloudwatch"
      policy_document = [
        {
          sid    = "GetQuery"
          effect = "Allow"
          actions = [
            "logs:StartQuery",
            "logs:GetQueryResults"
          ]
          resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:*_/srv/*/shared/log/*"
          ]
        }
      ]
    }
  ]
}
