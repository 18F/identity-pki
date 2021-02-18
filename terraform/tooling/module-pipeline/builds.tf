# This file contains all the codebuild jobs that are used by the pipeline

# How to run a terraform plan
resource "aws_codebuild_project" "auto_terraform_plan" {
  name           = "auto_terraform_${local.clean_tf_dir}_plan"
  description    = "auto-terraform ${var.tf_dir}"
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
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform"
      stream_name = "${var.tf_dir}-${var.gitref}"
    }
  }

  source {
    type = "CODEPIPELINE"
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
      - cd terraform/$TF_DIR
      - . ./env-vars.sh
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - export ORIG_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
      - export ORIG_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
      - export ORIG_AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::$aws_account_id:role/AutoTerraform" --role-session-name "auto-tf-plan")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - 
      - # XXX should we init things here? or just do it one time by hand?  ./bin/deploy/configure_state_bucket.sh
      - terraform init -backend-config=bucket=$TERRAFORM_STATE_BUCKET -backend-config=key=terraform-$TF_DIR.tfstate -backend-config=dynamodb_table=$ID_state_lock_table -backend-config=region=$TERRAFORM_STATE_BUCKET_REGION
      - terraform plan -detailed-exitcode -lock-timeout=120s || export EXITCODE=$?
      - |
        if [ "$EXITCODE" = "" ] ; then
          echo "================================  No changes: stop pipeline"
          export AWS_ACCESS_KEY_ID=$ORIG_AWS_ACCESS_KEY_ID
          export AWS_SECRET_ACCESS_KEY=$ORIG_AWS_SECRET_ACCESS_KEY
          export AWS_SESSION_TOKEN=$ORIG_AWS_SESSION_TOKEN
          EXE_NAME=$(echo $CODEBUILD_INITIATOR | awk -F/ '{print $2}')
          EXE_ID=$(aws codepipeline get-pipeline-state --region "${var.region}" --name "$EXE_NAME" | jq -r ".stageStates[] | select(.actionStates[].latestExecution.externalExecutionId == \"$CODEBUILD_BUILD_ID\") | .latestExecution.pipelineExecutionId")
)
          aws codepipeline stop-pipeline-execution --pipeline-name "auto_terraform_${local.clean_tf_dir}_plan" --pipeline-execution-id "$EXE_ID" --abandon --reason no_changes
        elif [ "$EXITCODE" -eq "1" ] ; then
          echo "================================ Error: fail the build"
          (exit 1)
        else
          echo "================================ There are changes: proceed to the next step"
          (exit 0)
        fi

  post_build:
    commands:
      - echo ============== Terraform plan completed on `date`
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
  name           = "auto_terraform_${local.clean_tf_dir}_apply"
  description    = "auto-terraform ${var.tf_dir}"
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
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform"
      stream_name = "${var.tf_dir}-${var.gitref}"
    }
  }

  source {
    type = "CODEPIPELINE"
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
      - cd terraform/$TF_DIR
      - . ./env-vars.sh
      - unset AWS_PROFILE
      - export AWS_STS_REGIONAL_ENDPOINTS=regional
      - roledata=$(aws sts assume-role --role-arn "arn:aws:iam::$aws_account_id:role/AutoTerraform" --role-session-name "auto-tf-apply")
      - export AWS_ACCESS_KEY_ID=$(echo $roledata | jq -r .Credentials.AccessKeyId)
      - export AWS_SECRET_ACCESS_KEY=$(echo $roledata | jq -r .Credentials.SecretAccessKey)
      - export AWS_SESSION_TOKEN=$(echo $roledata | jq -r .Credentials.SessionToken)
      - # XXX should we init things here? or just do it one time by hand?  ./bin/deploy/configure_state_bucket.sh
      - terraform init -backend-config=bucket=$TERRAFORM_STATE_BUCKET -backend-config=key=terraform-$TF_DIR.tfstate -backend-config=dynamodb_table=$ID_state_lock_table -backend-config=region=$TERRAFORM_STATE_BUCKET_REGION
      - terraform apply -auto-approve -lock-timeout=120s

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
resource "aws_codebuild_project" "auto_terraform_test" {
  name           = "auto_terraform_${local.clean_tf_dir}_test"
  description    = "auto-terraform ${var.tf_dir}"
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
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "auto-terraform"
      stream_name = "${var.tf_dir}-${var.gitref}"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = <<EOT
version: 0.2

phases:
  build:
    commands:
      - cd terraform/$TF_DIR/
      - . ./env-vars.sh
      - |
        if [ -x tests/test.sh ] ; then
          echo "tests found:  "
          cd tests
          ./test.sh
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
