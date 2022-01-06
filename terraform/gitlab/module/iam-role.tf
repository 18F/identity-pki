resource "aws_iam_role" "gitlab" {
  name               = "${var.env_name}_gitlab_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json

  inline_policy {
    name   = "${var.env_name}-gitlab-auto-eip"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEIPDescribeAndAssociate",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAddresses",
                "ec2:AssociateAddress"
            ],
            "Resource": "*"
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-certificates"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab-cloudwatch-agent"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab-cloudwatch-logs"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab-describe_instances"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab-ebvolume"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/domain": "${var.env_name}.gitlab.identitysandbox.gov"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:volume/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Name": "login-gitaly-${var.env_name}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:DetachVolume"
            ],
            "Resource": "arn:aws:ec2:*:*:volume/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Name": "login-gitlab-${var.env_name}"
                }
            }
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-s3buckets"
    policy = <<EOM
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:ListBucket"
          ],
          "Resource": [
              "arn:aws:s3:::gitlab-${var.env_name}-artifacts",
              "arn:aws:s3:::gitlab-${var.env_name}-backups",
              "arn:aws:s3:::gitlab-${var.env_name}-external-diffs",
              "arn:aws:s3:::gitlab-${var.env_name}-lfs-objects",
              "arn:aws:s3:::gitlab-${var.env_name}-uploads",
              "arn:aws:s3:::gitlab-${var.env_name}-packages",
              "arn:aws:s3:::gitlab-${var.env_name}-dependency-proxy",
              "arn:aws:s3:::gitlab-${var.env_name}-terraform-state",
              "arn:aws:s3:::gitlab-${var.env_name}-pages"
          ]
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObject"
          ],
          "Resource": [
              "arn:aws:s3:::gitlab-${var.env_name}-artifacts/*",
              "arn:aws:s3:::gitlab-${var.env_name}-backups/*",
              "arn:aws:s3:::gitlab-${var.env_name}-external-diffs/*",
              "arn:aws:s3:::gitlab-${var.env_name}-lfs-objects/*",
              "arn:aws:s3:::gitlab-${var.env_name}-uploads/*",
              "arn:aws:s3:::gitlab-${var.env_name}-packages/*",
              "arn:aws:s3:::gitlab-${var.env_name}-dependency-proxy/*",
              "arn:aws:s3:::gitlab-${var.env_name}-terraform-state/*",
              "arn:aws:s3:::gitlab-${var.env_name}-pages/*"
          ]
      }
  ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab-secrets"
    policy = <<EOM
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
  inline_policy {
    name   = "${var.env_name}-gitlab-sns-publish-alerts"
    policy = <<EOM
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
  inline_policy {
    name   = "${var.env_name}-gitlab-ssm-access"
    policy = <<EOM
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
}

resource "aws_iam_role" "gitlab_runner" {
  name               = "${var.env_name}_gitlab_runner_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json

  inline_policy {
    name   = "${var.env_name}-gitlab-ecr"
    policy = <<EOM
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
            "ecr:GetAuthorizationToken",
      			"ecr:BatchCheckLayerAvailability",
      			"ecr:InitiateLayerUpload",
      			"ecr:UploadLayerPart",
      			"ecr:CompleteLayerUpload",
      			"ecr:PutImage"
        ],
        "Resource": [
            "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/ecr-public/*",
            "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/quay/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:DescribeImages",
            "ecr:DescribeImageScanFindings",
            "ecr:DescribeRepositories",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:GetRepositoryPolicy",
            "ecr:ListImages",
            "ecr:ListTagsForResource"
        ],
        "Resource": "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*",
        "Condition": {
            "StringEquals": {
                "aws:ResourceTag/gitlab_${var.env_name}_build": "read"
            }
        }
    },
    {
        "Effect": "Allow",
        "Action": [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeImages",
            "ecr:DescribeImageScanFindings",
            "ecr:DescribeRepositories",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:GetRepositoryPolicy",
            "ecr:InitiateLayerUpload",
            "ecr:ListImages",
            "ecr:ListTagsForResource",
            "ecr:PutImage",
            "ecr:UploadLayerPart"
        ],
        "Resource": "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*",
        "Condition": {
            "StringEquals": {
                "aws:ResourceTag/gitlab_${var.env_name}_build": "write"
            }
        }
    }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-gitlab_runner-certificates"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab_runner-cloudwatch-agent"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab_runner-cloudwatch-logs"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab_runner-common-secrets"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab_runner-describe_instances"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-gitlab_runner-secrets"
    policy = <<EOM
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
  inline_policy {
    name   = "${var.env_name}-gitlab_runner-sns-publish-alerts"
    policy = <<EOM
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
  inline_policy {
    name   = "${var.env_name}-gitlab_runner-ssm-access"
    policy = <<EOM
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
  inline_policy {
    name   = "${var.env_name}-gitlab_runner-shared-cache"
    policy = <<EOM
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
}

resource "aws_iam_role" "obproxy" {
  name               = "${var.env_name}_obproxy_iam_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_from_vpc.json

  inline_policy {
    name   = "${var.env_name}-obproxy-auto-eip"
    policy = <<EOM
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEIPDescribeAndAssociate",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAddresses",
                "ec2:AssociateAddress"
            ],
            "Resource": "*"
        }
    ]
}
EOM
  }

  inline_policy {
    name   = "${var.env_name}-obproxy-certificates"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-obproxy-cloudwatch-agent"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-obproxy-cloudwatch-logs"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-obproxy-describe_instances"
    policy = <<EOM
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

  inline_policy {
    name   = "${var.env_name}-obproxy-secrets"
    policy = <<EOM
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
  inline_policy {
    name   = "${var.env_name}-obproxy-sns-publish-alerts"
    policy = <<EOM
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
  inline_policy {
    name   = "${var.env_name}-obproxy-ssm-access"
    policy = <<EOM
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
}
