# This file contains all the codebuild jobs that are used by the pipeline

locals {
  vars_files    = "-var-file $CODEBUILD_SRC_DIR_gitlab_${var.cluster_name}_private_output/vars/base.tfvars -var-file $CODEBUILD_SRC_DIR_gitlab_${var.cluster_name}_private_output/vars/account_global_${var.account}.tfvars -var-file $CODEBUILD_SRC_DIR_gitlab_${var.cluster_name}_private_output/vars/gitlab_${var.cluster_name}.tfvars"
  state_bucket  = "login-dot-gov-eks.${var.account}-${var.state_bucket_region}"
  tf_config_key = "tf-state/${var.cluster_name}"
}

# How to run a terraform plan
resource "aws_codebuild_project" "auto_tf_gitlab_plan" {
  name          = "auto_tf_gitlab_${var.cluster_name}_plan"
  description   = "auto-terraform gitlab ${var.cluster_name}"
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
      name  = "TF_VAR_cluster_name"
      value = var.cluster_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-tf-gitlab/${var.cluster_name}-${var.gitref}/plan"
      stream_name = var.gitref
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
      - mkdir -p terraform/.terraform
      - mv /tmp/plugins terraform/.terraform/

  build:
    commands:
      - cd terraform/
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-gitlab-plan-${var.cluster_name}")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION=${var.region}
      - 
      - aws eks update-kubeconfig --name "${var.cluster_name}"
      - kubectl version
      - terraform init -backend-config=bucket=${local.state_bucket} -backend-config=key=${local.tf_config_key} -backend-config=dynamodb_table=eks_terraform_locks -backend-config=region=${var.state_bucket_region}
      - terraform plan -lock-timeout=180s -out /plan.tfplan ${local.vars_files} 2>&1 | tee /plan.out

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
resource "aws_codebuild_project" "auto_tf_gitlab_apply" {
  name          = "auto_tf_gitlab_${var.cluster_name}_apply"
  description   = "auto-terraform gitlab ${var.cluster_name}"
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
      name  = "TF_VAR_cluster_name"
      value = var.cluster_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform-gitlab/${var.cluster_name}-${var.gitref}/apply"
      stream_name = var.gitref
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
      - mkdir -p terraform/.terraform
      - mv /tmp/plugins terraform/.terraform/

  build:
    commands:
      - cd terraform
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::${var.account}:role/AutoTerraform" --role-session-name "auto-tf-gitlab-apply-${var.cluster_name}")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - export AWS_REGION="${var.region}"
      - 
      - aws eks update-kubeconfig --name "${var.cluster_name}"
      - terraform init -backend-config=bucket=${local.state_bucket} -backend-config=key=${local.tf_config_key} -backend-config=dynamodb_table=eks_terraform_locks -backend-config=region=${var.state_bucket_region}
      - terraform apply -auto-approve -lock-timeout=180s $CODEBUILD_SRC_DIR_gitlab_${var.cluster_name}_plan_output/plan.tfplan
      - aws eks update-kubeconfig --name "$TF_VAR_cluster_name"
      - kubectl exec -it deployment.apps/teleport-cluster -n teleport -- tctl create -f < ./teleport-roles.yaml


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



# How to run tests
resource "aws_codebuild_project" "auto_tf_gitlab_test" {
  name          = "auto_tf_gitlab_${var.cluster_name}_test"
  description   = "auto-terraform gitlab ${var.cluster_name}"
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
      name  = "TF_VAR_cluster_name"
      value = var.cluster_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform-gitlab/${var.cluster_name}-${var.gitref}/test"
      stream_name = var.gitref
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
      - cd tests
      - sh -x ./test.sh

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
