# This is where a pipeline is set up.

locals {
  clean_tf_dir     = replace(var.tf_dir, "/[/.-]/", "_")
  get_private_repo = can(regex("gitlab", var.tf_dir))
  recycle_and_test = local.get_private_repo ? ["enabled"] : []
}

# pipeline that does the plan/approve/deploy/test
resource "aws_codepipeline" "auto_tf_pipeline" {
  name     = "auto_terraform_${local.clean_tf_dir}_"
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
      output_artifacts = ["${local.clean_tf_dir}__source_output"]

      configuration = {
        Owner                = "18F"
        Repo                 = "identity-devops"
        Branch               = var.gitref
        OAuthToken           = data.aws_s3_object.identity_devops_oauthkey.body
        PollForSourceChanges = "true"
      }
    }

    dynamic "action" {
      for_each = local.recycle_and_test
      content {
        name             = "identity_devops_private"
        category         = "Source"
        owner            = "ThirdParty"
        provider         = "GitHub"
        version          = "1"
        namespace        = "PrivateSource"
        output_artifacts = ["${local.clean_tf_dir}__private_output"]

        configuration = {
          Owner                = "18F"
          Repo                 = "identity-devops-private"
          Branch               = "main"
          OAuthToken           = data.aws_s3_object.identity_devops_oauthkey.body
          PollForSourceChanges = "true"
        }
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name     = "Plan"
      category = "Test"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"
      input_artifacts = compact([
        "${local.clean_tf_dir}__source_output",
        local.get_private_repo ? "${local.clean_tf_dir}__private_output" : ""
      ])
      output_artifacts = ["${local.clean_tf_dir}__plan_output"]

      configuration = {
        ProjectName          = "auto_terraform_${local.clean_tf_dir}__plan"
        PrimarySource        = "${local.clean_tf_dir}__source_output"
        EnvironmentVariables = <<EOF
[
  {"name": "IDCOMMIT", "value": "#{Source.CommitId}"},
  {"name": "IDBRANCH", "value": "#{Source.BranchName}"}%{if local.get_private_repo},
  {"name": "IDPRIVATECOMMIT", "value": "#{PrivateSource.CommitId}"},
  {"name": "IDPRIVATEBRANCH", "value": "#{PrivateSource.BranchName}"}%{endif}
]
EOF
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name     = "Apply"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"
      input_artifacts = compact([
        "${local.clean_tf_dir}__source_output",
        "${local.clean_tf_dir}__plan_output",
        local.get_private_repo ? "${local.clean_tf_dir}__private_output" : ""
      ])

      configuration = {
        ProjectName          = "auto_terraform_${local.clean_tf_dir}__apply"
        PrimarySource        = "${local.clean_tf_dir}__source_output"
        EnvironmentVariables = <<EOF
[
  {"name": "IDCOMMIT", "value": "#{Source.CommitId}"},
  {"name": "IDBRANCH", "value": "#{Source.BranchName}"}%{if local.get_private_repo},
  {"name": "IDPRIVATECOMMIT", "value": "#{PrivateSource.CommitId}"},
  {"name": "IDPRIVATEBRANCH", "value": "#{PrivateSource.BranchName}"}%{endif}
]
EOF
      }
    }
  }


  dynamic "stage" {
    for_each = local.recycle_and_test
    content {
      name = "NodeRecycle"

      action {
        name            = "NodeRecycle"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        input_artifacts = ["${local.clean_tf_dir}__source_output"]

        configuration = {
          ProjectName = "auto_terraform_${local.clean_tf_dir}__noderecycle"
        }
      }
    }
  }


  dynamic "stage" {
    for_each = local.recycle_and_test
    content {
      name = "Test"

      action {
        name            = "Build"
        category        = "Test"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        input_artifacts = ["${local.clean_tf_dir}__source_output"]

        configuration = {
          ProjectName          = "auto_terraform_${local.clean_tf_dir}__test"
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
}

# notifications!
resource "aws_codestarnotifications_notification_rule" "pipeline" {
  detail_type = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded"
  ]

  name     = "auto_terraform_${local.clean_tf_dir}__event_notifications"
  resource = aws_codepipeline.auto_tf_pipeline.arn

  target {
    address = join(":", [
      "arn:aws:sns:${var.region}",
      "${data.aws_caller_identity.current.account_id}:${var.events_sns_topic}"
    ])
  }
}
