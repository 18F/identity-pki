module "escrowread-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "EscrowRead"
  enabled                         = var.iam_account_alias == "login-prod" || var.iam_account_alias == "login-sandbox" ? true : false
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  permissions_boundary_policy_arn = var.permission_boundary_policy_name != "" ? data.aws_iam_policy.permission_boundary_policy[0].arn : ""
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
