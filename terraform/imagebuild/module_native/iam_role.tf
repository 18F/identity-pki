resource "aws_iam_role" "codepipeline" {
  name               = local.codepipeline_role_name
  description        = "Allows AWS CodePipeline in the imagebuild pipeline to start a build via AWS CodeBuild and access AWS S3 resources."
  assume_role_policy = data.aws_iam_policy_document.codepipeline.json

  inline_policy {
    name   = "CodePipelineRolePolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "s3:GetObject",
                        "s3:GetObjectVersion",
                        "s3:GetBucketVersioning"
                    ],
                    "Resource": [
                        "${aws_s3_bucket.codepipeline.arn}",
                        "${aws_s3_bucket.codepipeline.arn}/*",
                        "arn:aws:s3:::${var.git2s3_bucket_name}",
                        "arn:aws:s3:::${var.git2s3_bucket_name}/*",
                        "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}/packer_config/*"
                    ],
                    "Effect": "Allow"
                },
                {
                    "Action": [
                        "s3:PutObject"
                    ],
                    "Resource": [
                        "${aws_s3_bucket.codepipeline.arn}",
                        "${aws_s3_bucket.codepipeline.arn}/*"
                    ],
                    "Effect": "Allow"
                },
                {
                    "Action": [
                        "codebuild:BatchGetBuilds",
                        "codebuild:StartBuild"
                    ],
                    "Resource": [
                        "${aws_codebuild_project.base_image.arn}",
                        "${aws_codebuild_project.rails_image.arn}"
                    ],
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }
}

resource "aws_iam_role" "codebuild" {
  name               = local.codebuild_role_name
  description        = "Allows AWS CodeBuild in the imagebuild pipeline to perform specific actions and access resources such as AWS S3 or CloudWatch."
  assume_role_policy = data.aws_iam_policy_document.codebuild.json

  managed_policy_arns = []

  inline_policy {
    name   = "CodeBuildBasePolicy"
    policy = <<-EOM
        {
          "Statement": [
            {
                "Effect": "Allow",
                "Resource": [
                    "${aws_cloudwatch_log_group.imagebuild_base.arn}:*",
                    "${aws_cloudwatch_log_group.imagebuild_rails.arn}:*"
                ],
                "Action": [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "${aws_s3_bucket.codepipeline.arn}",
                    "${aws_s3_bucket.codepipeline.arn}/*"
                ],
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:GetObjectVersion",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "codebuild:CreateReportGroup",
                    "codebuild:CreateReport",
                    "codebuild:UpdateReport",
                    "codebuild:BatchPutTestCases"
                ],
                "Resource": [
                    "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/${local.base_pipeline_name}",
                    "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/${local.rails_pipeline_name}"
                ]
            }
          ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildCrissupbPolicy"
    policy = <<-EOM
        {
          "Statement": [
            {
                "Effect": "Allow",
                "Resource": [
                    "${aws_s3_bucket.codepipeline.arn}/*"
                ],
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:GetObjectVersion",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation"
                ]
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:s3:::codebuild-imagebaserole-outputbucket-k3ulvdsui2sy",
                    "arn:aws:s3:::codebuild-imagebaserole-outputbucket-k3ulvdsui2sy/*"
                ],
                "Action": [
                    "s3:PutObject",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation"
                ]
            }
          ]
        }
    EOM
  }


  inline_policy {
    name   = "CodeBuildS3ROPolicy"
    policy = <<-EOM
        {
          "Statement": [   

            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:GetObjectVersion"
                ],
                "Resource": [
                    "arn:aws:s3:::${var.git2s3_bucket_name}/${local.identity_base_image_zip_s3_path}"
                ]
            },
            {
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:s3:::${var.git2s3_bucket_name}"
                ],
                "Action": [
                    "s3:ListBucket",
                    "s3:GetBucketAcl",
                    "s3:GetBucketLocation"
                ]
            }
          ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildVPCPolicy"
    policy = <<-EOM
        {
          "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateNetworkInterface",
                    "ec2:DeleteNetworkInterface",
                    "ec2:DescribeDhcpOptions",
                    "ec2:DescribeNetworkInterfaces",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeVpcs"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateNetworkInterfacePermission"
                ],
                "Resource": "*",
                "Condition": {
                    "StringEquals": {
                        "ec2:Subnet": [
                            "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/${var.private_subnet_id}"
                        ]
                    }
                }
            }
          ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildCloudWatchEventsPolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "events:PutEvents"
                    ],
                    "Resource": "*",
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildIAMPolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "iam:PassRole",
                        "iam:GetRole"
                    ],
                    "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.packer_role_name}",
                    "Effect": "Allow"
                },
                {
                    "Action": [
                        "iam:GetInstanceProfile"
                    ],
                    "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${local.packer_instance_profile_name}",
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildLogPolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents",
                        "logs:DescribeLogGroups",
                        "logs:DescribeLogStreams"
                    ],
                    "Resource": [
                        "${aws_cloudwatch_log_group.imagebuild_base.arn}:*",
                        "${aws_cloudwatch_log_group.imagebuild_rails.arn}:*"
                    ],
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildPackerPolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Condition": {
                        "StringLike": {
                            "ec2:KeyPairName": "packer*"
                        }
                    },
                    "Action": [
                        "ec2:CreateKeypair",
                        "ec2:DeleteKeypair"
                    ],
                    "Resource": "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key-pair/*",
                    "Effect": "Allow",
                    "Sid": "Ec2KeypairAccess"
                },
                {
                    "Condition": {
                        "StringEquals": {
                            "ec2:InstanceProfile": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${local.packer_instance_profile_name}"
                        }
                    },
                    "Action": [
                        "ec2:AttachVolume",
                        "ec2:DeleteVolume",
                        "ec2:DetachVolume",
                        "ec2:ModifyInstanceAttribute",
                        "ec2:StopInstances",
                        "ec2:TerminateInstances"
                    ],
                    "Resource": [
                        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
                    ],
                    "Effect": "Allow",
                    "Sid": "Ec2ModifyConditionals"
                },
                {
                    "Action": [
                        "ec2:CopyImage",
                        "ec2:CreateImage",
                        "ec2:CreateSnapshot",
                        "ec2:CreateTags",
                        "ec2:CreateVolume",
                        "ec2:DeleteSnapshot",
                        "ec2:DeregisterImage",
                        "ec2:DescribeImageAttribute",
                        "ec2:DescribeImages",
                        "ec2:DescribeInstances",
                        "ec2:DescribeRegions",
                        "ec2:DescribeSecurityGroups",
                        "ec2:DescribeSnapshots",
                        "ec2:DescribeSubnets",
                        "ec2:DescribeTags",
                        "ec2:DescribeVolumes",
                        "ec2:ModifyImageAttribute",
                        "ec2:ModifySnapshotAttribute",
                        "ec2:RegisterImage",
                        "ec2:RunInstances",
                        "ec2:StartInstances"
                    ],
                    "Resource": "*",
                    "Effect": "Allow",
                    "Sid": "Ec2GeneralAllow"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildParameterPolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "ssm:GetParameters"
                    ],
                    "Resource": [
                        "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/CodeBuild/*"
                    ],
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildPipelinePolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "s3:PutObject",
                        "s3:GetObject",
                        "s3:GetObjectVersion"
                    ],
                    "Resource": [
                        "arn:aws:s3:::*-artifact*"
                    ],
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildSecretsCommonPolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "s3:GetObject",
                        "s3:GetObjectVersion"
                    ],
                    "Resource": [
                        "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/GeoIP2-City.mmdb",
                        "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/pwned-passwords.txt"
                    ],
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "CodeBuildSourcePolicy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "s3:GetObject",
                        "s3:GetObjectVersion"
                    ],
                    "Resource": [
                        "arn:aws:s3:::${var.git2s3_bucket_name}/*"
                    ],
                    "Effect": "Allow"
                }
            ]
        }
    EOM
  }
}

resource "aws_iam_role" "packer" {
  name               = local.packer_role_name
  description        = "Allows AWS CodeBuild in the imagebuild pipeline to generate AMIs using HashiCorp Packer."
  assume_role_policy = data.aws_iam_policy_document.packer.json

  inline_policy {
    name   = "CodeBuildPackerS3Policy"
    policy = <<-EOM
        {
            "Statement": [
                {
                    "Action": [
                        "s3:List*",
                        "s3:Get*"
                    ],
                    "Resource": [
                        "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/*",
                        "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}/common/"
                    ],
                    "Effect": "Allow",
                    "Sid": "AllowBucketAndObjects"
                },
                {
                    "Condition": {
                        "StringEquals": {
                            "s3:prefix": [
                                "common/",
                                ""
                            ],
                            "s3:delimiter": "/"
                        }
                    },
                    "Action": "s3:ListBucket",
                    "Resource": [
                        "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}",
                        "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
                    ],
                    "Effect": "Allow",
                    "Sid": "AllowRootAndTopListing"
                },
                {
                    "Condition": {
                        "StringLike": {
                            "s3:prefix": [
                                "common/"
                            ]
                        }
                    },
                    "Action": "s3:ListBucket",
                    "Resource": [
                        "arn:aws:s3:::login-gov.secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}",
                        "arn:aws:s3:::login-gov.app-secrets.${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
                    ],
                    "Effect": "Allow",
                    "Sid": "AllowSubListing"
                },
                {
                    "Action": [
                        "s3:GetObject",
                        "s3:ListBucket"
                    ],
                    "Resource": [
                        "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}",
                        "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}/*"
                    ],
                    "Effect": "Allow",
                    "Sid": "SoftwareArtifacts"
                }
            ]
        }
    EOM
  }

  inline_policy {
    name   = "S3ArtifactsAccess"
    policy = <<-EOM
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "S3ArtifactsAccess",
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:ListBucket"
                    ],
                    "Resource": [
                        "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}",
                        "arn:aws:s3:::login-gov-public-artifacts-${data.aws_region.current.name}/*"
                    ]
                }
            ]
        }
    EOM
  }
}

resource "aws_iam_role" "cloudwatch_events" {
  name               = "${var.name}-${data.aws_region.current.name}-${var.env_name}-cloudwatch-events"
  description        = "Allows AWS CloudWatch events to trigger the execution of the imagebuild pipeline via AWS CodePipeline."
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_events.json

  inline_policy {
    name   = "CodePipeline"
    policy = <<-EOM
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "CodePipeline",
                    "Effect": "Allow",
                    "Action": [
                        "codepipeline:StartPipelineExecution"
                    ],
                    "Resource": [
                        "${aws_codepipeline.base_image.arn}",
                        "${aws_codepipeline.rails_image.arn}"
                    ]
                }
            ]
        }
    EOM
  }
}