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
  statement {
    sid    = "AuroraClusterDeletionPrevent"
    effect = "Deny"
    actions = [
      "rds:DeleteDBCluster",
    ]
    resources = [
      "arn:aws:rds:*:*:cluster:*int*",
      "arn:aws:rds:*:*:cluster:*staging*",
      "arn:aws:rds:*:*:cluster:*prod*",
    ]
  }
  statement {
    sid    = "GlobalClusterDeletionPrevent"
    effect = "Deny"
    actions = [
      "rds:DeleteGlobalCluster",
    ]
    resources = [
      "arn:aws:rds:*:*:global-cluster:*int*",
      "arn:aws:rds:*:*:global-cluster:*staging*",
      "arn:aws:rds:*:*:global-cluster:*prod*",
    ]
  }
}

resource "aws_iam_policy" "rds_delete_prevent" {
  name        = "RDSDeletePrevent"
  path        = "/"
  description = "Prevent deletion of int, staging and prod rds instances"
  policy      = data.aws_iam_policy_document.rds_delete_prevent.json
}
