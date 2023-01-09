
data "aws_iam_policy_document" "iam_permission_boundary" {
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
  statement {
    sid    = "DeleteDBBackupandSnapshotPrevent"
    effect = "Deny"
    actions = [
      "rds:DeleteDBClusterSnapshot",
      "rds:DeleteDBInstanceAutomatedBackup",
      "rds:DeleteDBSnapshot"
    ]
    resources = [
      "arn:aws:rds:*:*:*:*int*",
      "arn:aws:rds:*:*:*:*staging*",
      "arn:aws:rds:*:*:*:*prod*",
    ]
  }
  statement {
    sid    = "DeleteDNSHostedZonePrevent"
    effect = "Deny"
    actions = [
      "route53:DeleteHostedZone"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/Z2DA4DCW3GKJVW", # login.gov
      "arn:aws:route53:::hostedzone/Z16FONIR8CZGWM", # identitysandbox.gov
      "arn:aws:route53:::hostedzone/ZEYKSG9SJ951W",  # login.gov.internal (int)
      "arn:aws:route53:::hostedzone/Z2XX1V1EBJTJ8K", # 16.172.in-addr.arpa (int)
      "arn:aws:route53:::hostedzone/Z1ZBRRO92N8G72", # login.gov.internal (staging)
      "arn:aws:route53:::hostedzone/Z29P7LNIL2XATE", # 16.172.in-addr.arpa (staging)
      "arn:aws:route53:::hostedzone/Z3SVVCHC17PLF9", # login.gov.internal (prod)
      "arn:aws:route53:::hostedzone/Z32KM8TXXW3ATV", # 16.172.in-addr.arpa (prod)
    ]
  }
  statement {
    sid    = "RegionRestriction"
    effect = "Deny"
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values = [
        "us-west-2",
        "us-east-1",
        "us-east-2",
      ]
    }
  }
  statement {
    sid    = "CloudTrailPrevent"
    effect = "Deny"
    actions = [
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail"
    ]
    resources = [
      "arn:aws:cloudtrail:*:*:trail/login-gov-cloudtrail",
    ]
  }

}


resource "aws_iam_policy" "permission_boundary_policy" {
  name        = "PermissionBoundaryPolicy"
  path        = "/"
  description = "Permission Boundary Policy for all Roles"
  policy      = data.aws_iam_policy_document.iam_permission_boundary.json
}
