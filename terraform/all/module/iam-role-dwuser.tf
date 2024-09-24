data "aws_iam_policy" "redshift_read_only" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftReadOnlyAccess"
}

data "aws_iam_policy" "query_editor_no_sharing" {
  arn = "arn:aws:iam::aws:policy/AmazonRedshiftQueryEditorV2NoSharing"
}

locals {
  dwuser_dns_policies = var.dnssec_zone_exists ? [data.aws_iam_policy.dnssec_disable_prevent[0].name] : []
  dwuser_additional_policies = [
    data.aws_iam_policy.redshift_read_only.name,
    data.aws_iam_policy.query_editor_no_sharing.name,
  ]
  dwuser_custom_iam_policies = flatten([local.dwuser_dns_policies, local.dwuser_additional_policies])

}

module "dwuser-assumerole" {
  source = "github.com/18F/identity-terraform//iam_assumerole?ref=5aa7231e4a3a91a9f4869311fbbaada99a72062b"
  #source = "../../../../identity-terraform/iam_assumerole"

  role_name                       = "DWUser"
  enabled                         = contains(local.enabled_roles, "iam_dwuser_enabled")
  master_assumerole_policy        = data.aws_iam_policy_document.master_account_assumerole.json
  custom_iam_policies             = local.dwuser_custom_iam_policies
  permissions_boundary_policy_arn = aws_iam_policy.permissions_boundary.arn

  iam_policies = [
    {
      policy_name        = "DWUser1"
      policy_description = "Policy for DWUser role"
      policy_document = [
        {
          sid       = "AllBucketsList"
          effect    = "Allow"
          actions   = ["s3:ListAllMyBuckets"]
          resources = ["arn:aws:s3:::*"]
        },
        {
          sid    = "QueryEditorV2KMSKeyAccess"
          effect = "Allow"
          actions = [
            "kms:GenerateDataKey",
            "kms:Decrypt"
          ]
          resources = ["*"]
          conditions = [
            {
              test     = "StringEquals"
              variable = "kms:viaService"
              values   = ["sqlworkbench.us-west-2.amazonaws.com"]
            },
            {
              test     = "StringEquals"
              variable = "kms:CallerAccount"
              values   = [data.aws_caller_identity.current.account_id]
            }
          ]
        },
        {
          sid    = "RedshiftQueryExecution"
          effect = "Allow"
          actions = [
            "tag:GetResources",
            "redshift:ViewQueriesFromConsole",
            "redshift:ModifySavedQuery",
            "redshift:FetchResults",
            "redshift:ExecuteQuery",
            "redshift:DeleteSavedQueries",
            "redshift:CreateSavedQuery"
          ]
          resources = ["*"]
        }
      ]
    }
  ]
}

data "aws_iam_policy_document" "dwuser_redshift_access" {
  count = module.dwuser-assumerole != null && contains(local.enabled_roles, "iam_dwuser_enabled") ? 1 : 0
  statement {
    sid    = "RedshiftUserAccess"
    effect = "Allow"
    actions = [
      "redshift:GetClusterCredentials",
    ]
    resources = [
      "arn:aws:redshift:us-west-2:*:cluster:*",
      "arn:aws:redshift:us-west-2:*:dbname:*/analytics",
      "arn:aws:redshift:us-west-2:*:dbuser:*/$${redshift:DbUser}"
    ]
    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "aws:userid"
      values = [
        "${module.dwuser-assumerole.iam_assumable_role.unique_id}:$${redshift:DbUser}",
      ]
    }
  }
}

resource "aws_iam_policy" "dwuser_redshift_access" {
  count  = module.dwuser-assumerole != null && contains(local.enabled_roles, "iam_dwuser_enabled") ? 1 : 0
  name   = "DWUserDataWarehouseAccess"
  policy = data.aws_iam_policy_document.dwuser_redshift_access[0].json
}

resource "aws_iam_role_policy_attachment" "dwuser_redshift_access" {
  count      = module.dwuser-assumerole != null && contains(local.enabled_roles, "iam_dwuser_enabled") ? 1 : 0
  role       = module.dwuser-assumerole.iam_assumable_role.name
  policy_arn = aws_iam_policy.dwuser_redshift_access[0].arn
}
