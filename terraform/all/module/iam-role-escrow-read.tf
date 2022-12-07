module "escrowread-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=e7ad5ef38f724b31911248a74173e9fee3bbf045"

  role_name                = "EscrowRead"
  enabled                  = var.iam_account_alias == "login-prod" || var.iam_account_alias == "login-sandbox" ? true : false
  master_assumerole_policy = data.aws_iam_policy_document.master_account_assumerole.json
  iam_policies = [
    {
      policy_name        = "EscrowRead"
      policy_description = "Policy to allow EscrowRead role to Decrypt/GetObject from escrow s3 buckets"
      policy_document = [
        {
          sid    = "ListEscrowBucket"
          effect = "Allow"
          actions = [
            "s3:ListBucket",
            "s3:ListBucketVersions",
            "s3:GetObject"
          ]
          resources = [
            "arn:aws:s3:::login-gov-escrow*"
          ]
        },
        {
          sid    = "ShowBuckets"
          effect = "Allow"
          actions = [
            "s3:ListAllMyBuckets",
          ]
          resources = [
            "*",
          ]
        }
      ]
    }
  ]
}
