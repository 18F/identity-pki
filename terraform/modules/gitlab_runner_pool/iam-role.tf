resource "aws_iam_role" "gitlab_runner" {
  name_prefix        = "${var.env_name}_gitlab_runner_iam_role"
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
  inline_policy {}
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
                      "aws:ResourceTag/gitlab_runner_access": "write"
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
              "Resource": "*",
              "Condition": {
                  "StringEquals": {
                      "aws:ResourceTag/gitlab_runner_access": "read"
                  }
              }
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

# allow SSM service core functionality
resource "aws_iam_role_policy" "gitlab-runner-ssm-access" {
  role        = aws_iam_role.gitlab_runner.id
  name_prefix = "${var.env_name}-gitlab_runner-ssm-access"
  policy      = <<-EOM
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "SSMCoreAccess",
                  "Effect": "Allow",
                  "Action": [
                      "ssmmessages:OpenDataChannel",
                      "ssmmessages:OpenControlChannel",
                      "ssmmessages:CreateDataChannel",
                      "ssmmessages:CreateControlChannel",
                      "ssm:UpdateInstanceInformation",
                      "ssm:UpdateInstanceAssociationStatus",
                      "ssm:UpdateAssociationStatus",
                      "ssm:PutInventory",
                      "ssm:PutConfigurePackageResult",
                      "ssm:PutComplianceItems",
                      "ssm:ListInstanceAssociations",
                      "ssm:ListAssociations",
                      "ssm:GetParameters",
                      "ssm:GetParameter",
                      "ssm:GetManifest",
                      "ssm:GetDocument",
                      "ssm:GetDeployablePatchSnapshotForInstance",
                      "ssm:DescribeDocument",
                      "ssm:DescribeAssociation",
                      "ec2messages:SendReply",
                      "ec2messages:GetMessages",
                      "ec2messages:GetEndpoint",
                      "ec2messages:FailMessage",
                      "ec2messages:DeleteMessage",
                      "ec2messages:AcknowledgeMessage"
                  ],
                  "Resource": "*"
              },
              {
                  "Sid": "CloudWatchAgentAccess",
                  "Effect": "Allow",
                  "Action": [
                      "ec2:DescribeVolumes",
                      "ec2:DescribeTags",
                      "cloudwatch:PutMetricData"
                  ],
                  "Resource": "*"
              },
              {
                  "Sid": "CloudWatchLogsAccess",
                  "Effect": "Allow",
                  "Action": [
                      "logs:PutLogEvents",
                      "logs:DescribeLogStreams",
                      "logs:DescribeLogGroups",
                      "logs:CreateLogStream",
                      "logs:CreateLogGroup"
                  ],
                  "Resource": "*"
              }
          ]
      }
    EOM
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

