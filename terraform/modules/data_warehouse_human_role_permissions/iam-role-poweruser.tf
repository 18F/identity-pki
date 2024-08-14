data "aws_iam_policy_document" "redshift_administrator" {
  statement {
    sid    = "Redshift"
    effect = "Allow"
    actions = [
      "redshift:CancelQuery",
      "redshift:CancelQuerySession",
      "redshift:CancelResize",
      "redshift:CopyClusterSnapshot",
      "redshift:CreateAuthenticationProfile",
      "redshift:CreateSavedQuery",
      "redshift:CreateScheduledAction",
      "redshift:CreateTags",
      "redshift:DeleteSavedQueries",
      "redshift:DeleteScheduledAction",
      "redshift:DeleteTags",
      "redshift:Describe*",
      "redshift:ExecuteQuery",
      "redshift:FetchResults",
      "redshift:GetClusterCredentials",
      "redshift:GetClusterCredentialsWithIAM",
      "redshift:List*",
      "redshift:ModifyAquaConfiguration",
      "redshift:ModifyAuthenticationProfile",
      "redshift:ModifySavedQuery",
      "redshift:ModifyScheduledAction",
      "redshift:PauseCluster",
      "redshift:RebootCluster",
      "redshift:ResumeCluster",
      "redshift:ViewQueriesFromConsole",
      "redshift:ViewQueriesInConsole",
    ]
    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "power_user" {
  source_policy_documents = [
    data.aws_iam_policy_document.redshift_administrator.json,
    data.aws_iam_policy_document.redshift_query_execution_access.json,
    data.aws_iam_policy_document.query_editor_v2_kms_access.json,
  ]
}


resource "aws_iam_policy" "poweruser" {
  name   = "DataWarehousePowerUser"
  policy = data.aws_iam_policy_document.power_user.json
}

resource "aws_iam_role_policy_attachment" "poweruser" {
  role       = data.aws_iam_role.targets["PowerUser"].name
  policy_arn = aws_iam_policy.poweruser.arn
}
