# This file contains all the codebuild jobs that are used by the pipeline

# This lets us set the vars files if somebody gives us an env_name
locals {
  vars_files      = (var.env_name == "" ? "" : "-var-file $CODEBUILD_SRC_DIR_${local.clean_tf_dir}_${var.env_name}_private_output/vars/base.tfvars -var-file $CODEBUILD_SRC_DIR_${local.clean_tf_dir}_${var.env_name}_private_output/vars/account_global_${var.account}.tfvars -var-file $CODEBUILD_SRC_DIR_${local.clean_tf_dir}_${var.env_name}_private_output/vars/${var.env_name}.tfvars")
  envstr          = (var.env_name == "" ? "" : "the ${var.env_name} environment in ")
  tf_top_dir      = (var.env_name == "" ? "${regex("[a-z]+/??", var.tf_dir)}/module" : "app")
  state_bucket    = "login-gov.tf-state.${var.account}-${var.state_bucket_region}"
  tf_config_key   = (var.env_name == "" ? "terraform-${var.tf_dir}.tfstate" : "terraform-app/terraform-${var.env_name}.tfstate")
  recycletest_env = (var.env_name == "" ? var.recycletest_env_name : var.env_name)
}

# How to run a terraform plan
resource "aws_codebuild_project" "auto_terraform_plan" {
  name          = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_plan"
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
      name  = "TF_VAR_env_name"
      value = var.env_name
    }
    environment_variable {
      name  = "TF_VAR_account_id"
      value = var.account
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform/${var.tf_dir}-${var.env_name}-${var.gitref}/plan"
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
      - aws s3 cp s3://${var.auto_tf_bucket_id}/${var.tfbundle} /tmp/ --no-progress
      - unzip /tmp/${var.tfbundle}
      - mv terraform /usr/local/bin/
      - cd $CODEBUILD_SRC_DIR
      - mkdir -p terraform/$TF_DIR/.terraform
      - mv /tmp/plugins terraform/$TF_DIR/.terraform/

  build:
    commands:
      - cp .terraform.lock.hcl terraform/$TF_DIR
      - cp versions.tf terraform/${local.tf_top_dir}
      - cd terraform/$TF_DIR
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-plan-${local.clean_tf_dir}-${var.env_name}")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION=${var.region}
      - 
      - terraform init -plugin-dir=.terraform/plugins -lockfile=readonly -backend-config=bucket=${local.state_bucket} -backend-config=key=${local.tf_config_key} -backend-config=dynamodb_table=terraform_locks -backend-config=region=${var.state_bucket_region}
      - terraform providers lock -fs-mirror=.terraform/plugins
      - terraform plan -lock-timeout=180s -out /plan.tfplan ${local.vars_files} 2>&1 > /plan.out
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
  name          = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_apply"
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
      name  = "TF_VAR_env_name"
      value = var.env_name
    }
    environment_variable {
      name  = "TF_VAR_account_id"
      value = var.account
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform/${var.tf_dir}-${var.env_name}-${var.gitref}/apply"
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
      - aws s3 cp s3://${var.auto_tf_bucket_id}/${var.tfbundle} /tmp/ --no-progress
      - unzip /tmp/${var.tfbundle}
      - mv terraform /usr/local/bin/
      - cd $CODEBUILD_SRC_DIR
      - mkdir -p terraform/$TF_DIR/.terraform
      - mv /tmp/plugins terraform/$TF_DIR/.terraform/

  build:
    commands:
      - cp .terraform.lock.hcl terraform/$TF_DIR
      - cp versions.tf terraform/${local.tf_top_dir}
      - cd terraform/$TF_DIR
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-apply-${local.clean_tf_dir}-${var.env_name}")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION="${var.region}"
      - 
      - terraform init -plugin-dir=.terraform/plugins -lockfile=readonly -backend-config=bucket=${local.state_bucket} -backend-config=key=${local.tf_config_key} -backend-config=dynamodb_table=terraform_locks -backend-config=region=${var.state_bucket_region}
      - terraform providers lock -fs-mirror=.terraform/plugins
      - terraform apply -auto-approve -lock-timeout=180s $CODEBUILD_SRC_DIR_${local.clean_tf_dir}_${var.env_name}_plan_output/plan.tfplan

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

# How to run a terraform node reycle
resource "aws_codebuild_project" "auto_terraform_noderecycle" {
  name          = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_noderecycle"
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
      group_name  = "auto-terraform/${var.tf_dir}-${var.env_name}-${var.gitref}/noderecycle"
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
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-apply-${local.clean_tf_dir}-${var.env_name}")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION="${var.region}"
      - |
        if [ -x recycle.sh ] ; then
          echo "recycle found:  executing"
          ./recycle.sh "${local.recycletest_env}"
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
resource "aws_codebuild_project" "auto_terraform_test" {
  name          = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_test"
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
      name  = "TF_VAR_env_name"
      value = var.env_name
    }
    environment_variable {
      name  = "TF_VAR_account_id"
      value = var.account
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform/${var.tf_dir}-${var.env_name}-${var.gitref}/test"
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
        if [ -x tests/test.sh ] ; then
          echo "tests found:  executing"
          cd tests
          sh -x ./test.sh ${local.recycletest_env} ${var.recycletest_domain}
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
