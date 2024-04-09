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
      "rds:RemoveFromGlobalCluster",
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
      "rds:RemoveFromGlobalCluster",
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
  statement {
    sid    = "LogGroupDeletePrevent"
    effect = "Deny"
    actions = [
      "logs:DeleteLogGroup",
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/var/log/cloud-init.log",
      "arn:aws:logs:*:*:log-group:/var/log/cloud-init-output.log",
      "arn:aws:logs:*:*:log-group:*int*",
      "arn:aws:logs:*:*:log-group:*staging*",
      "arn:aws:logs:*:*:log-group:*prod*",
    ]
  }
  statement {
    sid    = "LogStreamDeletePrevent"
    effect = "Deny"
    actions = [
      "logs:DeleteLogStream",
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/var/log/cloud-init.log:log-stream:*",
      "arn:aws:logs:*:*:log-group:/var/log/cloud-init-output.log:log-stream:*",
      "arn:aws:logs:*:*:log-group:*int*:log-stream:*",
      "arn:aws:logs:*:*:log-group:*staging*:log-stream:*",
      "arn:aws:logs:*:*:log-group:*prod*:log-stream:*",
    ]
  }
  statement {
    sid    = "KMSDeletePrevent"
    effect = "Deny"
    actions = [
      "kms:Delete*",
      "kms:DisableKey*",
      "kms:ScheduleKeyDeletion",
      "kms:UpdateAlias",
    ]
    resources = [
      # "arn:aws:kms:*:*:key/*"       # use once replica keys are re-removed
      "arn:aws:kms:us-west-2:*:key/*"
    ]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:ResourceAliases"

      values = [
        "alias/int-login-dot-gov-keymaker",
        "alias/staging-login-dot-gov-keymaker",
        "alias/prod-login-dot-gov-keymaker",
        "alias/int-login-dot-gov-keymaker-multi-region",
        "alias/staging-login-dot-gov-keymaker-multi-region",
        "alias/prod-login-dot-gov-keymaker-multi-region",
      ]
    }
  }
  statement {
    sid    = "KMSAliasDeletePrevent"
    effect = "Deny"
    actions = [
      "kms:DeleteAlias",
      "kms:UpdateAlias",
    ]
    resources = [
      "arn:aws:kms:us-west-2:*:alias/int-login-dot-gov-keymaker",
      "arn:aws:kms:us-west-2:*:alias/staging-login-dot-gov-keymaker",
      "arn:aws:kms:us-west-2:*:alias/prod-login-dot-gov-keymaker",
      #"arn:aws:kms:*:*:alias/int-login-dot-gov-keymaker-multi-region",
      #"arn:aws:kms:*:*:alias/staging-login-dot-gov-keymaker-multi-region",
      #"arn:aws:kms:*:*:alias/prod-login-dot-gov-keymaker-multi-region",
      "arn:aws:kms:us-west-2:*:alias/int-login-dot-gov-keymaker-multi-region",
      "arn:aws:kms:us-west-2:*:alias/staging-login-dot-gov-keymaker-multi-region",
      "arn:aws:kms:us-west-2:*:alias/prod-login-dot-gov-keymaker-multi-region",
    ]
  }
}

resource "aws_iam_policy" "rds_delete_prevent" {
  name        = "RDSDeletePrevent"
  path        = "/"
  description = "Prevent deletion of int, staging and prod rds instances"
  policy      = data.aws_iam_policy_document.rds_delete_prevent.json
}
