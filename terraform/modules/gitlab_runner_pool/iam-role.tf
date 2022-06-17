resource "aws_iam_role" "gitlab_runner" {
  name               = "${var.env_name}-${var.gitlab_runner_pool_name}_gitlab_runner_role"
  assume_role_policy = <<-EOM
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOM
}

resource "aws_iam_role_policy" "gitlab-ecr-write" {
  count       = var.enable_ecr_write ? 1 : 0
  name_prefix = "${var.env_name}-gitlab-ecr-write"
  role        = aws_iam_role.gitlab_runner.id
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "ecr:BatchImportUpstreamImage",
                  "ecr:BatchCheckLayerAvailability",
                  "ecr:GetDownloadUrlForLayer",
                  "ecr:GetRepositoryPolicy",
                  "ecr:DescribeRepositories",
                  "ecr:ListImages",
                  "ecr:DescribeImages",
                  "ecr:BatchGetImage",
                  "ecr:GetLifecyclePolicy",
                  "ecr:GetLifecyclePolicyPreview",
                  "ecr:ListTagsForResource",
                  "ecr:DescribeImageScanFindings",
                  "ecr:InitiateLayerUpload",
                  "ecr:UploadLayerPart",
                  "ecr:CompleteLayerUpload",
                  "ecr:PutImage"
              ],
              "Resource": "*",
              "Condition": {
                  "StringEquals": {
                      "aws:ResourceTag/gitlab_${var.env_name}_${var.gitlab_runner_pool_name}": "write"
                  }
              }
          }
          ]
      }
   EOM
}

resource "aws_iam_role_policy" "gitlab-ecr" {
  name_prefix = "${var.env_name}-gitlab-ecr"
  role        = aws_iam_role.gitlab_runner.id
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "ecr:GetAuthorizationToken"
              ],
              "Resource": "*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "ecr:BatchImportUpstreamImage",
                  "ecr:BatchCheckLayerAvailability",
                  "ecr:GetDownloadUrlForLayer",
                  "ecr:GetRepositoryPolicy",
                  "ecr:DescribeRepositories",
                  "ecr:ListImages",
                  "ecr:DescribeImages",
                  "ecr:BatchGetImage",
                  "ecr:GetLifecyclePolicy",
                  "ecr:GetLifecyclePolicyPreview",
                  "ecr:ListTagsForResource",
                  "ecr:DescribeImageScanFindings"
              ],
              "Resource": "*"
          }
          ]
      }
    EOM
}

resource "aws_iam_role_policy" "gitlab-runner-certificates" {
  name_prefix = "${var.env_name}-gitlab_runner-certificates"
  role        = aws_iam_role.gitlab_runner.id
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "AllowCertificatesBucketIntegrationTest",
                  "Effect": "Allow",
                  "Action": "s3:*",
                  "Resource": [
                    "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/",
                    "arn:aws:s3:::login-gov.internal-certs.${data.aws_caller_identity.current.account_id}-${var.region}/${var.env_name}/*"
                  ]
              }
          ]
      }
  EOM
}

resource "aws_iam_role_policy" "gitlab-runner-cloudwatch-agent" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-cloudwatch-agent"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "allowCloudWatchAgent",
                  "Effect": "Allow",
                  "Action": [
                      "ec2:DescribeVolumes",
                      "ec2:DescribeTags",
                      "cloudwatch:PutMetricData"
                  ],
                  "Resource": "*"
              }
          ]
      }
    EOM
}

resource "aws_iam_role_policy" "gitlab-runner-cloudwatch-logs" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-cloudwatch-logs"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "allowCloudWatch",
                  "Effect": "Allow",
                  "Action": [
                      "logs:PutLogEvents",
                      "logs:DescribeLogStreams",
                      "logs:DescribeLogGroups",
                      "logs:CreateLogStream",
                      "logs:CreateLogGroup"
                  ],
                  "Resource": "arn:aws:logs:*:*:*"
              }
          ]
      }
    EOM
}

resource "aws_iam_role_policy" "gitlab-runner-common-secrets" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-common-secrets"
  policy      = <<-EOM
      {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowBucketAndObjects",
                "Effect": "Allow",
                "Action": [
                    "s3:List*",
                    "s3:Get*"
                ],
                "Resource": [
                    "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
                    "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/"
                ]
            },
            {
                "Sid": "AllowRootAndTopListing",
                "Effect": "Allow",
                "Action": "s3:ListBucket",
                "Resource": "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
                "Condition": {
                    "StringEquals": {
                        "s3:delimiter": [
                            "/"
                        ],
                        "s3:prefix": [
                            "",
                            "common/",
                            "${var.env_name}/"
                        ]
                    }
                }
            },
            {
                "Sid": "AllowSubListing",
                "Effect": "Allow",
                "Action": "s3:ListBucket",
                "Resource": "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
                "Condition": {
                    "StringLike": {
                        "s3:prefix": [
                            "common/",
                            "${var.env_name}/*"
                        ]
                    }
                }
            },
            {
                "Sid": "AllowCompleteLifecycleHook",
                "Effect": "Allow",
                "Action": [
                    "autoscaling:RecordLifecycleActionHeartbeat",
                    "autoscaling:CompleteLifecycleAction"
                ],
                "Resource": "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*"
            }
        ]
      }
    EOM
}

resource "aws_iam_role_policy" "gitlab-runner-describe-instances" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-describe_instances"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "AllowDescribeInstancesIntegrationTest",
                  "Effect": "Allow",
                  "Action": "ec2:DescribeInstances",
                  "Resource": "*"
              }
          ]
      }
    EOM
}

resource "aws_iam_role_policy" "gitlab-runner-secrets" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-secrets"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "AllowBucketAndObjects",
                  "Effect": "Allow",
                  "Action": [
                      "s3:List*",
                      "s3:Get*"
                  ],
                  "Resource": [
                      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/*",
                      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/common/",
                      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/*",
                      "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*/${var.env_name}/"
                  ]
              },
              {
                  "Sid": "AllowRootAndTopListing",
                  "Effect": "Allow",
                  "Action": "s3:ListBucket",
                  "Resource": "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
                  "Condition": {
                      "StringEquals": {
                          "s3:delimiter": [
                              "/"
                          ],
                          "s3:prefix": [
                              "",
                              "common/",
                              "${var.env_name}/"
                          ]
                      }
                  }
              },
              {
                  "Sid": "AllowSubListing",
                  "Effect": "Allow",
                  "Action": "s3:ListBucket",
                  "Resource": "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-*",
                  "Condition": {
                      "StringLike": {
                          "s3:prefix": [
                              "common/",
                              "${var.env_name}/*"
                          ]
                      }
                  }
              },
              {
                  "Sid": "AllowCompleteLifecycleHook",
                  "Effect": "Allow",
                  "Action": [
                      "autoscaling:RecordLifecycleActionHeartbeat",
                      "autoscaling:CompleteLifecycleAction"
                  ],
                  "Resource": "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/${var.env_name}-*"
              }
          ]
      }
      EOM
}

# allow all instances to send a dying SNS notice
resource "aws_iam_role_policy" "gitlab-runner-sns-publish-alerts" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-sns-publish-alerts"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "allowSNSPublish",
                  "Effect": "Allow",
                  "Action": "SNS:Publish",
                  "Resource": "${var.slack_events_sns_hook_arn}"
              }
          ]
      }
    EOM
}

# allow SSM access via documents / key generation + usage
resource "aws_iam_role_policy" "gitlab-runner-ssm-access" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-ssm-access"
  policy      = var.ssm_access_policy
}

# allow runners to use a shared cache
resource "aws_iam_role_policy" "gitlab-runner-shared-cache" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-shared-cache"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "SharedCache",
                  "Effect": "Allow",
                  "Action": [
                      "s3:*",
                      "s3:PutObject",
                      "s3:GetObjectVersion",
                      "s3:GetObject",
                      "s3:DeleteObject"
                  ],
                  "Resource": [
                    "arn:aws:s3:::login-gov-${var.env_name}-gitlabcache-${data.aws_caller_identity.current.account_id}-${var.region}/",
                    "arn:aws:s3:::login-gov-${var.env_name}-gitlabcache-${data.aws_caller_identity.current.account_id}-${var.region}/*"
                  ]
              }
          ]
      }
      EOM
}

locals {
  gitlab_configbucket = var.gitlab_configbucket != "" ? var.gitlab_configbucket : "login-gov-${var.env_name}-gitlabconfig-${data.aws_caller_identity.current.account_id}-${var.region}"

}

# allow runners to get the config
resource "aws_iam_role_policy" "gitlab-runner-config" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-config"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "Config",
                  "Effect": "Allow",
                  "Action": [
                      "s3:GetObject"
                  ],
                  "Resource": [
                    "arn:aws:s3:::${local.gitlab_configbucket}/",
                    "arn:aws:s3:::${local.gitlab_configbucket}/*"
                  ]
              }
          ]
      }
      EOM
}

data "aws_iam_policy_document" "app_artifacts_bucket_role_policy_document" {
  statement {
    sid    = "AllowAppArtifactsBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      for account in var.destination_artifact_accounts : "arn:aws:s3:::login-gov.app-artifacts.${account}-${var.region}/*"
    ]
  }
}

data "aws_iam_policy_document" "idp_static_assets_role_bucket_role_policy_document" {
  statement {
    sid    = "AllowIDPStaticAssetsBucketAndObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = flatten([for account in var.destination_idp_static_accounts : ["arn:aws:s3:::login-gov-idp-static-*.${account}-${var.region}", "arn:aws:s3:::login-gov-idp-static-*.${account}-${var.region}/*"]])
  }
}

resource "aws_iam_role_policy" "app_artifacts_role_bucket_role_policy" {
  count = length(var.destination_artifact_accounts) > 0 ? 1 : 0

  name   = "${var.env_name}-upload-app-artifacts"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.app_artifacts_bucket_role_policy_document.json
}

resource "aws_iam_role_policy" "idp_static_assets_role_bucket_role_policy" {
  count = length(var.destination_idp_static_accounts) > 0 ? 1 : 0

  name   = "${var.env_name}-upload-idp-static-assets"
  role   = aws_iam_role.gitlab_runner.id
  policy = data.aws_iam_policy_document.idp_static_assets_role_bucket_role_policy_document.json
}

# attach AutoTerraform policies if needed
locals {
  auto_tf_policies = var.terraform_powers ? toset([
    "AutoTerraform1",
    "AutoTerraform2",
    "AutoTerraform3",
    "AutoTerraform4"
  ]) : []
}
resource "aws_iam_role_policy_attachment" "AutoTerraform" {
  for_each = local.auto_tf_policies

  role       = aws_iam_role.gitlab_runner.id
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${each.key}"
}
