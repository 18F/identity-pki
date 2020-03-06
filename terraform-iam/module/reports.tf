module "reports-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=master"

  role_name                = "ReportsReadOnly"
  enabled                  = var.iam_reports_enabled
  master_assumerole_policy = local.master_assumerole_policy
  custom_policy_arns       = local.custom_policy_arns

  iam_policies = [
    {
      policy_name        = "ReportsReadOnly"
      policy_description = "Policy for reporting group read-only access to Reports bucket"
      policy_document = [
        {
          sid    = "RROAllBuckets"
          effect = "Allow"
          actions = [
            "s3:ListAllMyBuckets"
          ]
          resources = [
            "arn:aws:s3:::*"
          ]
        },
        {
          sid    = "RROSeeBucket"
          effect = "Allow"
          actions = [
            "s3:ListBucket"
          ]
          resources = [
            var.reports_bucket_arn
          ]
        },
        {
          sid    = "RROGetObjects"
          effect = "Allow"
          actions = [
            "s3:GetObject"
          ]
          resources = [
            "${var.reports_bucket_arn}/*"
          ]
        }
      ]
    }
  ]
}
