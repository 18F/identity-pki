data "aws_iam_policy_document" "permissions_boundary" {

  # allow all services as used by all roles

  statement {
    sid    = "AllowedServices"
    effect = "Allow"
    actions = var.limit_allowed_services ? [
      "access-analyzer:*",
      "account:*",
      "acm:*",
      "acm-pca:*",
      "apigateway:*",
      "application-autoscaling:*",
      "aps:*",
      "athena:*",
      "autoscaling:*",
      "batch:*",
      "billing:*",
      "budget:*",
      "ce:*",
      "cloud9:*",
      "cloudformation:*",
      "cloudfront:*",
      "cloudhsm:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "codebuild:*",
      "codecommit:*",
      "codedeploy:*",
      "codepipeline:*",
      "codestar-notifications:*",
      "config:*",
      "consolidatedbilling:*",
      "cur:*",
      "dax:*",
      "detective:*",
      "dlm:*",
      "dms:*",
      "dynamodb:*",
      "ec2:*",
      "ec2messages:*",
      "ecr:*",
      "ecs:*",
      "eks:*",
      "elasticache:*",
      "elasticloadbalancing:*",
      "events:*",
      "firehose:*",
      "freetier:*",
      "glacier:*",
      "glue:*",
      "guardduty:*",
      "health:*",
      "iam:*",
      "inspector:*",
      "inspector2:*",
      "invoicing:*",
      "kinesis:*",
      "kinesisanalytics:*",
      "kms:*",
      "lambda:*",
      "logs:*",
      "macie:*",
      "macie2:*",
      "mobiletargeting:*",
      "network-firewall:*",
      "organizations:*",
      "payments:*",
      "pi:*",
      "pinpoint:*",
      "quicksight:*",
      "ram:*",
      "rds:*",
      "readonly:*",
      "redshift:*",
      "resource-groups:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "secretsmanager:*",
      "securityhub:*",
      "serverlessrepo:*",
      "ses:*",
      "shield:*",
      "sms-voice:*",
      "sns:*",
      "sqs:*",
      "ssm:*",
      "states:*",
      "sts:*",
      "support:*",
      "tag:*",
      "tax:*",
      "trustedadvisor:*",
      "waf:*",
      "waf-regional:*",
      "wafv2:*",
      "xray:*",
    ] : ["*"]
    resources = [
      "*"
    ]
  }
  # prevent deletion of int/staging/prod RDS; used by all roles
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

  # prevent deletion of main Route 53 Hosted Zones
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

  # prevent disabling of CloudTrail
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

  # deny removal/disabling of keymaker keys (single + multi-region)
  statement {
    sid    = "LogGroupDeletePrevent"
    effect = "Deny"
    actions = [
      "logs:DeleteLogGroup",
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/var/log/cloud-init.log",
      "arn:aws:logs:*:*:log-group:/var/log/cloud-init-output.log",
      "arn:aws:logs:*:*:log-group:int*",
      "arn:aws:logs:*:*:log-group:staging*",
      "arn:aws:logs:*:*:log-group:prod*",
      "arn:aws:logs:*:*:log-group:elacticache-int-redis",
      "arn:aws:logs:*:*:log-group:elacticache-staging-redis",
      "arn:aws:logs:*:*:log-group:elacticache-prod-redis",
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
      "arn:aws:logs:*:*:log-group:int*:log-stream:*",
      "arn:aws:logs:*:*:log-group:staging*:log-stream:*",
      "arn:aws:logs:*:*:log-group:prod*:log-stream:*",
      "arn:aws:logs:*:*:log-group:elacticache-int-redis:log-stream:*",
      "arn:aws:logs:*:*:log-group:elacticache-staging-redis:log-stream:*",
      "arn:aws:logs:*:*:log-group:elacticache-prod-redis:log-stream:*",
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
      "arn:aws:kms:*:*:key/*"
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
      "arn:aws:kms:*:*:alias/int-login-dot-gov-keymaker-multi-region",
      "arn:aws:kms:*:*:alias/staging-login-dot-gov-keymaker-multi-region",
      "arn:aws:kms:*:*:alias/prod-login-dot-gov-keymaker-multi-region",
    ]
  }

  # restrict to specified regions
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
      values   = var.permitted_regions
    }
  }

  # deny all actions from AI-centered AWS services
  statement {
    sid    = "AIServiceRestriction"
    effect = "Deny"
    actions = [
      "bedrock:*",
      "codeguru-profiler:*",
      "codeguru-reviewer:*",
      "codewhisperer:*",
      "titan:*",
      "comprehend:*",
      "comprehendmedical:*",
      "devops-guru:*",
      "forecast:*",
      "healthlake:*",
      "kendra:*",
      "lex:*",
      "lookoutmetrics:*",
      "personalize:*",
      "polly:*",
      "q:*",
      "rekognition:*",
      "textract:*",
      "transcribe:*",
      "transcribemedical:*",
      "translate:*",
      "health-omics:*",
      "health-imaging:*",
      "healthscribe:*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "permissions_boundary" {
  name = "PermissionsBoundary"
  path = "/"
  description = join(" ", [
    "Permissions Boundary policy attached to Assumable IAM roles. Includes full",
    "list of accessible services, plus region/service restrictions as necessary."
  ])
  policy = data.aws_iam_policy_document.permissions_boundary.json
}
