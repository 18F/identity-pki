resource "aws_codepipeline" "base_image" {
  name     = local.base_pipeline_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = var.repo
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      namespace        = "Source"
      version          = "1"
      output_artifacts = ["ImageSource"]

      configuration = {
        PollForSourceChanges = var.source_build_trigger
        S3Bucket             = var.git2s3_bucket_name
        S3ObjectKey          = local.identity_base_image_zip_s3_path
      }
    }
  }

  stage {
    name = "CodeBuild"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["ImageSource"]
      version          = "1"
      output_artifacts = ["AmiOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.base_image.name
      }
    }
  }

  tags = {}
}

resource "aws_codepipeline" "rails_image" {
  name     = local.rails_pipeline_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = var.repo
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      namespace        = "Source"
      version          = "1"
      output_artifacts = ["ImageSource"]

      configuration = {
        PollForSourceChanges = var.source_build_trigger
        S3Bucket             = var.git2s3_bucket_name
        S3ObjectKey          = local.identity_base_image_zip_s3_path
      }
    }
  }

  stage {
    name = "CodeBuild"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["ImageSource"]
      version          = "1"
      output_artifacts = ["AmiOutput"]

      configuration = {
        ProjectName = aws_codebuild_project.rails_image.name
      }
    }
  }

  tags = {}
}