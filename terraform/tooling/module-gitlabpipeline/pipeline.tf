# pipeline that does the plan/approve/deploy/test
resource "aws_codepipeline" "auto_tf_pipeline" {
  name     = "auto_tf_gitlab_${var.cluster_name}"
  role_arn = var.auto_tf_pipeline_role_arn

  artifact_store {
    type     = "S3"
    location = var.auto_tf_bucket_id
  }

  stage {
    name = "Source"

    action {
      name             = var.repo
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      namespace        = "Source"
      version          = "1"
      output_artifacts = ["gitlab_${var.cluster_name}_source_output"]

      configuration = {
        Owner      = "18F"
        Repo       = var.repo
        Branch     = var.gitref
        OAuthToken = data.aws_s3_bucket_object.identity_devops_oauthkey.body
      }
    }
    action {
      name             = "identity_devops_private"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      namespace        = "PrivateSource"
      output_artifacts = ["gitlab_${var.cluster_name}_private_output"]

      configuration = {
        Owner = "18F"
        Repo  = "identity-devops-private"
        # XXX change this back to main when this is all working
        Branch     = "main"
        OAuthToken = data.aws_s3_bucket_object.identity_devops_oauthkey.body
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
      input_artifacts  = ["gitlab_${var.cluster_name}_source_output", "gitlab_${var.cluster_name}_private_output"]
      output_artifacts = ["gitlab_${var.cluster_name}_plan_output"]

      configuration = {
        ProjectName   = "auto_tf_gitlab_${var.cluster_name}_plan"
        PrimarySource = "gitlab_${var.cluster_name}_source_output"
      }
    }
  }


  stage {
    name = "Apply"

    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["gitlab_${var.cluster_name}_source_output", "gitlab_${var.cluster_name}_plan_output", "gitlab_${var.cluster_name}_private_output"]

      configuration = {
        ProjectName   = "auto_tf_gitlab_${var.cluster_name}_apply"
        PrimarySource = "gitlab_${var.cluster_name}_source_output"
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
      input_artifacts = ["gitlab_${var.cluster_name}_source_output"]

      configuration = {
        ProjectName = "auto_tf_gitlab_${var.cluster_name}_test"
      }
    }
  }
}

# notifications!
resource "aws_codestarnotifications_notification_rule" "pipeline" {
  detail_type    = "BASIC"
  event_type_ids = ["codepipeline-pipeline-pipeline-execution-failed", "codepipeline-pipeline-pipeline-execution-succeeded"]

  name     = "auto_tf_gitlab_${var.cluster_name}_event_notifications"
  resource = aws_codepipeline.auto_tf_pipeline.arn

  target {
    address = "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:${var.events_sns_topic}"
  }
}
