# This is where a pipeline is set up.

locals {
  clean_tf_dir = replace(var.tf_dir, "/[/.-]/", "_")
}


# pipeline that does the plan/approve/deploy/test
resource "aws_codepipeline" "auto_tf_pipeline" {
  name     = "auto_terraform_${local.clean_tf_dir}_${var.env_name}"
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
      namespace        = "Source"
      version          = "1"
      output_artifacts = ["${local.clean_tf_dir}_${var.env_name}_source_output"]

      configuration = {
        Owner                = "18F"
        Repo                 = "identity-devops"
        Branch               = var.gitref
        OAuthToken           = data.aws_s3_bucket_object.identity_devops_oauthkey.body
        PollForSourceChanges = "true"
      }
    }
    action {
      name             = "identity_devops_private"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      namespace        = "PrivateSource"
      output_artifacts = ["${local.clean_tf_dir}_${var.env_name}_private_output"]

      configuration = {
        Owner                = "18F"
        Repo                 = "identity-devops-private"
        Branch               = "main"
        OAuthToken           = data.aws_s3_bucket_object.identity_devops_oauthkey.body
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "Plan"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["${local.clean_tf_dir}_${var.env_name}_source_output", "${local.clean_tf_dir}_${var.env_name}_private_output"]
      output_artifacts = ["${local.clean_tf_dir}_${var.env_name}_plan_output"]

      configuration = {
        ProjectName          = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_plan"
        PrimarySource        = "${local.clean_tf_dir}_${var.env_name}_source_output"
        EnvironmentVariables = <<EOF
[
  {"name": "IDCOMMIT", "value": "#{Source.CommitId}"},
  {"name": "IDBRANCH", "value": "#{Source.BranchName}"},
  {"name": "IDPRIVATECOMMIT", "value": "#{PrivateSource.CommitId}"},
  {"name": "IDPRIVATEBRANCH", "value": "#{PrivateSource.BranchName}"}
]
EOF
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
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output", "${local.clean_tf_dir}_plan_output}", "${local.clean_tf_dir}_private_output"]

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
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output", "${local.clean_tf_dir}_plan_output}", "${local.clean_tf_dir}_private_output"]

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
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output", "${local.clean_tf_dir}_plan_output}", "${local.clean_tf_dir}_private_output"]

  #     configuration = {
  #       ProjectName = "auto_terraform_${local.clean_tf_dir}_destroytestenv"
  #     }
  #   }
  # }

  # # Approval step
  # stage {
  #   name = "Approve"

  #   action {
  #     name     = "Approval"
  #     category = "Approval"
  #     owner    = "AWS"
  #     provider = "Manual"
  #     version  = "1"

  #   #   configuration = {
  #   #     NotificationArn = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.events_sns_topic}"
  #   #     CustomData = "${var.tf_dir} on ${var.gitref} needs approval for rollout to ${var.account}"
  #   #   }
  #   }
  # }

  stage {
    name = "Apply"

    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["${local.clean_tf_dir}_${var.env_name}_source_output", "${local.clean_tf_dir}_${var.env_name}_plan_output", "${local.clean_tf_dir}_${var.env_name}_private_output"]

      configuration = {
        ProjectName          = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_apply"
        PrimarySource        = "${local.clean_tf_dir}_${var.env_name}_source_output"
        EnvironmentVariables = <<EOF
[
  {"name": "IDCOMMIT", "value": "#{Source.CommitId}"},
  {"name": "IDBRANCH", "value": "#{Source.BranchName}"},
  {"name": "IDPRIVATECOMMIT", "value": "#{PrivateSource.CommitId}"},
  {"name": "IDPRIVATEBRANCH", "value": "#{PrivateSource.BranchName}"}
]
EOF
      }
    }
  }


  stage {
    name = "NodeRecycle"

    action {
      name            = "NodeRecycle"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["${local.clean_tf_dir}_${var.env_name}_source_output"]

      configuration = {
        ProjectName = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_noderecycle"
      }
    }
  }


  stage {
    name = "Test"

    action {
      name            = "Build"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["${local.clean_tf_dir}_${var.env_name}_source_output"]

      configuration = {
        ProjectName          = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_test"
        EnvironmentVariables = <<EOF
[
  {"name": "IDCOMMIT", "value": "#{Source.CommitId}"},
  {"name": "IDBRANCH", "value": "#{Source.BranchName}"},
  {"name": "IDPRIVATECOMMIT", "value": "#{PrivateSource.CommitId}"},
  {"name": "IDPRIVATEBRANCH", "value": "#{PrivateSource.BranchName}"}
]
EOF
      }
    }
  }
}

# notifications!
resource "aws_codestarnotifications_notification_rule" "pipeline" {
  detail_type    = "BASIC"
  event_type_ids = ["codepipeline-pipeline-pipeline-execution-failed", "codepipeline-pipeline-pipeline-execution-succeeded"]

  name     = "auto_terraform_${local.clean_tf_dir}_${var.env_name}_event_notifications"
  resource = aws_codepipeline.auto_tf_pipeline.arn

  target {
    address = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.events_sns_topic}"
  }
}
