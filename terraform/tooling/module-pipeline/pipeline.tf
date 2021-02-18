# This is where a pipeline is set up.

locals {
  clean_tf_dir = replace(var.tf_dir, "/[/.-]/", "_")
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

      configuration = {
        ProjectName = "auto_terraform_${local.clean_tf_dir}_plan"
      }
    }
  }

  # stage {
  #   name = "BuildTestEnv"

  #   action {
  #     name             = "BuildTestEnv"
  #     category         = "Build"
  #     owner            = "AWS"
  #     provider         = "CodeBuild"
  #     version          = "1"
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output"]

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
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output"]

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
  #     input_artifacts  = ["${local.clean_tf_dir}_source_output"]

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
      input_artifacts  = ["${local.clean_tf_dir}_source_output"]

      configuration = {
        ProjectName = "auto_terraform_${local.clean_tf_dir}_apply"
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
