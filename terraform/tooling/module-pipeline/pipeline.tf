# This is where a pipeline is set up.

locals {
  clean_tf_dir = replace(var.tf_dir, "/[/.-]/", "_")
}


# pipeline that does the plan/approve/deploy/test
resource "aws_codepipeline" "auto_tf_pipeline" {
  name     = "auto_terraform_${local.clean_tf_dir}_pipeline"
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
      output_artifacts = ["${local.clean_tf_dir}_plan_output"]

      configuration = {
        ProjectName = "auto_terraform_${local.clean_tf_dir}_plan"
      }
    }
  }

  # XXX Implement build/test/destroy of env in the scratch environment

  # stage {
  #   name = "BuildTestEnv"

  #   action {
  #     name             = "BuildTestEnv"
  #     category         = "Build"
  #     owner            = "AWS"
  #     provider         = "CodeBuild"
  #     version          = "1"
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output", "${local.clean_tf_dir}_plan_output}"]

  #     configuration = {
  #       ProjectName = "auto_terraform_${local.clean_tf_dir}_buildtestenv"
  #     }
  #   }
  # }

  # stage {
  #   name = "TestTestEnv"

  #   action {
  #     name             = "TestTestEnv"
  #     category         = "Test"
  #     owner            = "AWS"
  #     provider         = "CodeBuild"
  #     version          = "1"
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output", "${local.clean_tf_dir}_plan_output}"]

  #     configuration = {
  #       ProjectName = "auto_terraform_${local.clean_tf_dir}_testtestenv"
  #     }
  #   }
  # }

  # stage {
  #   name = "DestroyTestEnv"

  #   action {
  #     name             = "DestroyTestEnv"
  #     category         = "Build"
  #     owner            = "AWS"
  #     provider         = "CodeBuild"
  #     version          = "1"
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output", "${local.clean_tf_dir}_plan_output}"]

  #     configuration = {
  #       ProjectName = "auto_terraform_${local.clean_tf_dir}_destroytestenv"
  #     }
  #   }
  # }

  stage {
    name = "Apply"

    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["${local.clean_tf_dir}_source_output", "${local.clean_tf_dir}_plan_output"]

      configuration = {
        ProjectName = "auto_terraform_${local.clean_tf_dir}_apply"
        PrimarySource = "${local.clean_tf_dir}_source_output"
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "Build"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["${local.clean_tf_dir}_source_output"]

      configuration = {
        ProjectName = "auto_terraform_${local.clean_tf_dir}_test"
      }
    }
  }
}

# notifications!
resource "aws_codestarnotifications_notification_rule" "pipeline" {
  detail_type    = "BASIC"
  event_type_ids = ["codepipeline-pipeline-pipeline-execution-failed", "codepipeline-pipeline-pipeline-execution-started", "codepipeline-pipeline-pipeline-execution-succeeded"]

  name     = "auto_terraform_${local.clean_tf_dir}_event_notifications"
  resource = aws_codepipeline.auto_tf_pipeline.arn

  target {
    address = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.events_sns_topic}"
  }
}
