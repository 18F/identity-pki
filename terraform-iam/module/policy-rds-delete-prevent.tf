# prevent deletion of int/staging/prod RDS; used by all roles
data "aws_iam_policy_document" "rds_delete_prevent" {
  statement {
    sid    = "RDSDeletionPrevent"
    effect = "Deny"
    actions = [
      "rds:DeleteDBInstance",
    ]
    resources = [
      "arn:aws:rds:*:*:db:*int*",
      "arn:aws:rds:*:*:db:*staging*",
      "arn:aws:rds:*:*:db:*prod*",
    ]
  }
}

resource "aws_iam_policy" "rds_delete_prevent" {
  name        = "RDSDeletePrevent"
  path        = "/"
  description = "Prevent deletion of int, staging and prod rds instances"
  policy      = data.aws_iam_policy_document.rds_delete_prevent.json
}
