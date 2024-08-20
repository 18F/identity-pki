data "aws_iam_policy_document" "redshift_query_execution_access" {
  statement {
    sid    = "RedshiftQueryExecution"
    effect = "Allow"
    actions = [
      "redshift:CreateSavedQuery",
      "redshift:DeleteSavedQueries",
      "redshift:ExecuteQuery",
      "redshift:FetchResults",
      "redshift:ModifySavedQuery",
      "redshift:ViewQueriesFromConsole",
      "tag:GetResources"
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "query_editor_v2_kms_access" {
  statement {
    sid    = "QueryEditorV2KMSKeyAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:viaService"
      values   = [for region in var.permitted_regions : "sqlworkbench.${region}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
