# This file contains all the codebuild jobs that are used by the pipeline

# This lets us set the vars files if somebody gives us an env_name
locals {
  tf_top_dir    = "${regex("[a-z]+/??", var.tf_dir)}/module"
  state_bucket  = "login-gov.tf-state.${var.account}-${var.state_bucket_region}"
  tf_config_key = "terraform-${var.tf_dir}.tfstate"
}

data "aws_s3_object" "newrelic_api_key" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/newrelic_apikey"
}

# How to run a terraform plan
resource "aws_codebuild_project" "auto_terraform_plan" {
  name          = "auto_terraform_${local.clean_tf_dir}__plan"
  description   = "auto-terraform ${var.tf_dir}"
  build_timeout = "30"
  service_role  = var.auto_tf_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_DIR"
      value = var.tf_dir
    }
    environment_variable {
      name  = "TF_VAR_account_id"
      value = var.account
    }
    environment_variable {
      name  = "NEW_RELIC_API_KEY"
      value = data.aws_s3_object.newrelic_api_key.body
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform/${var.tf_dir}--${var.gitref}/plan"
      stream_name = "${var.tf_dir}-${var.gitref}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOT
version: 0.2
phases:
  install:
    commands:
      - cd /tmp/
      - |
        if [ -f "$CODEBUILD_SRC_DIR/.tfbundle" ] ; then
          export TFBUNDLE=$(cat "$CODEBUILD_SRC_DIR/.tfbundle")
        else
          export TFBUNDLE="${var.tfbundle}"
        fi
      - aws s3 cp "s3://${var.auto_tf_bucket_id}/$TFBUNDLE" /tmp/ --no-progress
      - unzip "/tmp/$TFBUNDLE"
      - mv terraform /usr/local/bin/
      - cd $CODEBUILD_SRC_DIR
      - mkdir -p terraform/$TF_DIR/.terraform
      - mv /tmp/plugins terraform/$TF_DIR/.terraform/
  build:
    commands:
      - cp .terraform.lock.hcl terraform/$TF_DIR
      - cp versions.tf terraform/${local.tf_top_dir}
      - rm -f terraform/modules/newrelic/versions.tf  # XXX I am not sure why we have to do this.
      - cp versions.tf terraform/modules/newrelic/    # XXX symlinks should work
      - cd terraform/$TF_DIR
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-plan-${local.clean_tf_dir}-")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION=${var.region}
      -
      - pwd
      - terraform init -plugin-dir=.terraform/plugins -lockfile=readonly -backend-config=bucket=${local.state_bucket} -backend-config=key=${local.tf_config_key} -backend-config=dynamodb_table=terraform_locks -backend-config=region=${var.state_bucket_region}
      - terraform providers lock -fs-mirror=.terraform/plugins
      - terraform plan -lock-timeout=180s -out /plan.tfplan 2>&1 > /plan.out
      - cat -n /plan.out
  post_build:
    commands:
      - echo "================================ Terraform plan completed on `date`"
artifacts:
  files:
    - /plan.out
    - /plan.tfplan
    EOT
  }
  source_version = var.gitref

  vpc_config {
    vpc_id = var.auto_tf_vpc_id

    subnets = [
      var.auto_tf_subnet_id,
    ]

    security_group_ids = [
      var.auto_tf_sg_id,
    ]
  }

  tags = {
    Environment = "Tooling"
  }
}

# How to run a terraform apply
resource "aws_codebuild_project" "auto_terraform_apply" {
  name          = "auto_terraform_${local.clean_tf_dir}__apply"
  description   = "auto-terraform ${var.tf_dir}"
  build_timeout = "30"
  service_role  = var.auto_tf_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_DIR"
      value = var.tf_dir
    }
    environment_variable {
      name  = "TF_VAR_account_id"
      value = var.account
    }
    environment_variable {
      name  = "NEW_RELIC_API_KEY"
      value = data.aws_s3_object.newrelic_api_key.body
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform/${var.tf_dir}--${var.gitref}/apply"
      stream_name = "${var.tf_dir}-${var.gitref}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOT
version: 0.2
phases:
  install:
    commands:
      - cd /tmp/
      - |
        if [ -f "$CODEBUILD_SRC_DIR/.tfbundle" ] ; then
          export TFBUNDLE=$(cat "$CODEBUILD_SRC_DIR/.tfbundle")
        else
          export TFBUNDLE="${var.tfbundle}"
        fi
      - aws s3 cp "s3://${var.auto_tf_bucket_id}/$TFBUNDLE" /tmp/ --no-progress
      - unzip "/tmp/$TFBUNDLE"
      - mv terraform /usr/local/bin/
      - cd $CODEBUILD_SRC_DIR
      - mkdir -p terraform/$TF_DIR/.terraform
      - mv /tmp/plugins terraform/$TF_DIR/.terraform/
  build:
    commands:
      - cp .terraform.lock.hcl terraform/$TF_DIR
      - cp versions.tf terraform/${local.tf_top_dir}
      - rm -f terraform/modules/newrelic/versions.tf  # XXX I am not sure why we have to do this.
      - cp versions.tf terraform/modules/newrelic/    # XXX symlinks should work
      - cd terraform/$TF_DIR
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-apply-${local.clean_tf_dir}-")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION="${var.region}"
      -
      - terraform init -plugin-dir=.terraform/plugins -lockfile=readonly -backend-config=bucket=${local.state_bucket} -backend-config=key=${local.tf_config_key} -backend-config=dynamodb_table=terraform_locks -backend-config=region=${var.state_bucket_region}
      - terraform providers lock -fs-mirror=.terraform/plugins
      - terraform plan -lock-timeout=180s -out /plan2.tfplan 2>&1 > /plan2.out # A bit ugly, but some things are generated dynamically here that need to be around for the plan to actually be applied.
      - terraform apply -auto-approve -lock-timeout=180s $CODEBUILD_SRC_DIR_${local.clean_tf_dir}__plan_output/plan.tfplan
  post_build:
    commands:
      - echo terraform apply completed on `date`
    EOT
  }
  source_version = var.gitref

  vpc_config {
    vpc_id = var.auto_tf_vpc_id

    subnets = [
      var.auto_tf_subnet_id,
    ]

    security_group_ids = [
      var.auto_tf_sg_id,
    ]
  }

  tags = {
    Environment = "Tooling"
  }
}

#### DEPRECATED; remove once all environment-based auto-tf stuff can be removed ####

# How to run a terraform node reycle
resource "aws_codebuild_project" "auto_terraform_noderecycle" {
  count = length(local.recycle_and_test)

  name          = "auto_terraform_${local.clean_tf_dir}__noderecycle"
  description   = "auto-terraform ${var.tf_dir} node recycle"
  build_timeout = "60"
  service_role  = var.auto_tf_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform/${var.tf_dir}--${var.gitref}/noderecycle"
      stream_name = "${var.tf_dir}-${var.gitref}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOT
version: 0.2
phases:
  install:
    commands:
      - echo "nothing to install yet"
  build:
    commands:
      - cd terraform/${var.tf_dir}
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-apply-${local.clean_tf_dir}-")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION="${var.region}"
      - |
        if [ -x recycle.sh ] ; then
          echo "recycle found:  executing"
          sh ./recycle.sh ${var.recycletest_env_name}
        elif [ -x ../recycle.sh ] ; then
          echo "recycle found in dir above us:  executing"
          sh ../recycle.sh ${var.recycletest_env_name}
        else
          echo "no recycle found:  continuing"
          exit 0
        fi
  post_build:
    commands:
      - echo terraform node recycle completed on `date`
    EOT
  }
  source_version = var.gitref

  vpc_config {
    vpc_id = var.auto_tf_vpc_id

    subnets = [
      var.auto_tf_subnet_id,
    ]

    security_group_ids = [
      var.auto_tf_sg_id,
    ]
  }

  tags = {
    Environment = "Tooling"
  }
}


# How to run tests
# Policy with the minimal set of perms for testing
resource "aws_iam_role_policy" "codebuild_test" {
  count = length(local.recycle_and_test)

  name = "${var.recycletest_env_name}_auto_tf_test_policy"
  role = aws_iam_role.codebuild_test[count.index].name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "arn:aws:codestar-notifications:${var.region}:${data.aws_caller_identity.current.account_id}:notificationrule*"
      ],
      "Action": [
        "codestar-notifications:DescribeNotificationRule"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "arn:aws:codepipeline:${var.region}:${data.aws_caller_identity.current.account_id}:auto_terraform*"
      ],
      "Action": [
        "codepipeline:GetPipeline",
        "codepipeline:GetPipelineState"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand"
      ],
      "Resource":[
        "arn:aws:ssm:${var.region}::document/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetCommandInvocation"
      ],
      "Resource":[
        "arn:aws:ssm:us-west-2:${data.aws_caller_identity.current.account_id}:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand"
      ],
      "Resource":[
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
      ],
      "Condition": {
          "StringLike": { "ssm:resourceTag/Name": [
            "asg-${var.recycletest_env_name}-gitlab"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand"
      ],
      "Resource":[
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
      ],
      "Condition": {
          "StringLike": { "ssm:resourceTag/Name": [
            "asg-${var.recycletest_env_name}-gitlab*"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetInventory"
      ],
      "Resource": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "autoscaling:Describe*",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:ListObjects",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::login-gov-${var.recycletest_env_name}-*",
        "arn:aws:s3:::auto-tf-bucket-${data.aws_caller_identity.current.account_id}",
        "arn:aws:s3:::auto-tf-bucket-${data.aws_caller_identity.current.account_id}/*"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Resource": "*",
      "Condition": {
          "StringEquals": { "autoscaling:ResourceTag/environment": "${var.recycletest_env_name}" }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "${var.auto_tf_subnet_arn}"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "codebuild_test" {
  count = length(local.recycle_and_test)
  name  = "${var.recycletest_env_name}_codebuild_test"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "auto_terraform_test" {
  count         = length(local.recycle_and_test)
  name          = "auto_terraform_${local.clean_tf_dir}__test"
  description   = "auto-terraform ${var.tf_dir}"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild_test[count.index].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_DIR"
      value = var.tf_dir
    }
    environment_variable {
      name  = "TF_VAR_account_id"
      value = var.account
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform/${var.tf_dir}--${var.gitref}/test"
      stream_name = "${var.tf_dir}-${var.gitref}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOT
version: 0.2
phases:
  install:
    runtime-versions:
      golang: 1.15
  build:
    commands:
      - cd terraform/$TF_DIR/
      - if [ -f ./env-vars.sh ] ; then . ./env-vars.sh ; fi
      - |
        unset AWS_PROFILE
        aws s3 cp s3://gitlab-${var.recycletest_env_name}-config/GITLAB_API_TOKEN /tmp/GITLAB_API_TOKEN
        if [ -f /tmp/GITLAB_API_TOKEN ] ; then
          echo "reading GITLAB_API_TOKEN"
          export GITLAB_API_TOKEN=$(cat /tmp/GITLAB_API_TOKEN)
        fi
        if [ -x tests/test.sh ] ; then
          echo "tests found:  executing"
          cd tests
          sh -x ./test.sh ${var.recycletest_env_name} ${var.recycletest_domain}
        elif [ -x ../tests/test.sh ] ; then
          echo "tests found in dir above us:  executing"
          cd ../tests
          sh -x ./test.sh ${var.recycletest_env_name} ${var.recycletest_domain}
        else
          echo "no tests found:  continuing"
          exit 0
        fi
  post_build:
    commands:
      - echo test completed on `date`
    EOT
  }
  source_version = var.gitref

  vpc_config {
    vpc_id = var.auto_tf_vpc_id

    subnets = [
      var.auto_tf_subnet_id,
    ]

    security_group_ids = [
      var.auto_tf_sg_id,
    ]
  }

  tags = {
    Environment = "Tooling"
  }
}