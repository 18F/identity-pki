locals {
  clean_tf_dir = replace(var.tf_dir, "/[/.-]/", "_")
}

# How to run a terraform plan
resource "aws_codebuild_project" "auto_terraform_plan" {
  name           = "auto_terraform_${local.clean_tf_dir}_plan"
  description    = "auto-terraform ${var.tf_dir}"
  build_timeout = "5"
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
      - aws s3 cp s3://${var.auto_tf_bucket_id}/terraform_0.13.5_linux_amd64 /usr/local/bin/terraform

  build:
    commands:
      - bin/tf-deploy $TF_DIR plan

  post_build:
    commands:
      - echo terraform plan completed on `date`
    EOT
  }
  source_version = var.gitref

  vpc_config {
    vpc_id = var.auto_tf_vpc_id

    subnets = [
      var.auto_tf_subnet1_id,
      var.auto_tf_subnet2_id,
    ]

    security_group_ids = [
      var.auto_tf_sg_id,
    ]
  }

  tags = {
    Environment = "Tooling"
  }
}


# pipeline that does the plan/approve/deploy/test
resource "aws_codepipeline" "auto_tf_pipeline" {
  name     = "${local.clean_tf_dir}_pipeline"
  role_arn = var.auto_tf_pipeline_role_arn

  artifact_store {
    type     = "S3"
    location = var.auto_tf_bucket_id
  }

  stage {
    name = "Source"

    action {
      name             = "identity-devops"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["${local.clean_tf_dir}_source_output"]

      configuration = {
        Owner      = "18F"
        Repo       = "identity-devops"
        Branch     = var.gitref
        OAuthToken = data.aws_s3_bucket_object.identity_devops_oauthkey.body
      }
    }

  }

  stage {
    name = "Plan"

    action {
      name             = "Build"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["${local.clean_tf_dir}_source_output"]
      # output_artifacts = ["${local.clean_tf_dir}_build_output"]

      configuration = {
        ProjectName = "auto_terraform_${local.clean_tf_dir}_plan"
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

    #   configuration = {
    #     NotificationArn = "${var.approve_sns_arn}"
    #     CustomData = "${var.approve_comment}"
    #     ExternalEntityLink = "${var.approve_url}"
    #   }
    }
  }

  # stage {
  #   name = "Deploy"

  #   action {
  #     name            = "Deploy"
  #     category        = "Deploy"
  #     owner           = "AWS"
  #     provider        = "CloudFormation"
  #     input_artifacts = ["${local.clean_tf_dir}_build_output"]
  #     version         = "1"

  #     configuration = {
  #       ActionMode     = "REPLACE_ON_FAILURE"
  #       Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
  #       OutputFileName = "CreateStackOutput.json"
  #       StackName      = "MyStack"
  #       TemplatePath   = "build_output::sam-templated.yaml"
  #     }
  #   }
  # }

  # stage {
  #   name = "Test"

  #   action {
  #     name            = "Test"
  #     category        = "Test"
  #     owner           = "AWS"
  #     provider        = "CloudFormation"
  #     input_artifacts = ["${local.clean_tf_dir}_build_output"]
  #     version         = "1"

  #     configuration = {
  #       ActionMode     = "REPLACE_ON_FAILURE"
  #       Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
  #       OutputFileName = "CreateStackOutput.json"
  #       StackName      = "MyStack"
  #       TemplatePath   = "build_output::sam-templated.yaml"
  #     }
  #   }
  # }
}
