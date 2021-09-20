data "aws_iam_account_alias" "current" {}

data "aws_s3_bucket_object" "git2s3_output_bucket" {
  bucket = var.artifact_bucket
  key    = "git2s3/OutputBucketName"
}

locals {
  aws_alias     = trimprefix(data.aws_iam_account_alias.current.account_alias, "login-")
  git2s3_bucket = trimspace(data.aws_s3_bucket_object.git2s3_output_bucket.body)
}

resource "aws_cloudformation_stack" "image_network_stack" {
  name          = "login-image-creation"
  template_body = file("${path.module}/login-vpc-image-build.template")
  parameters = {
    PrivateSubnet1CIDR = var.image_build_private_cidr
    PublicSubnet1CIDR  = var.image_build_public_cidr
    VPCCIDR            = var.image_build_vpc_cidr
  }
  capabilities = ["CAPABILITY_IAM"]
}

resource "aws_ssm_parameter" "source_file_name" {
  name        = "ImageCreationSourceFile"
  type        = "String"
  description = "Path/name of the branch-specific source ZIP file placed in the CodeSync bucket."
  value       = "18F/identity-base-image/${var.code_branch}/18F_identity-base-image.zip"
}

resource "aws_ssm_parameter" "project_name" {
  for_each = toset(var.ami_types)

  name        = "CodeBuildProject-${each.key}"
  type        = "String"
  description = "Name of the CodeBuild project (referenced by both ${each.key} stacks)"
  value       = "login-image-${each.key}"
}

resource "aws_cloudformation_stack" "image_codebuild_stack" {
  for_each = toset(var.ami_types)

  name          = join("", ["CodeBuild-Image", title(each.key), "Role"])
  template_body = file("${path.module}/login-codebuild-image.template")
  parameters = {
    AccountAlias       = local.aws_alias
    NetworkStackName   = aws_cloudformation_stack.image_network_stack.name
    ProjectName        = aws_ssm_parameter.project_name[each.key].name
    RoleName           = each.key
    SourceFileName     = aws_ssm_parameter.source_file_name.name
    Git2S3OutputBucket = local.git2s3_bucket
  }
  capabilities = ["CAPABILITY_IAM"]
}

resource "aws_cloudformation_stack" "image_codepipeline_stack" {
  for_each = toset(var.ami_types)

  name          = join("", ["CodePipeline-Image", title(each.key), "Role"])
  template_body = file("${path.module}/login-codepipeline-image.template")
  parameters = {
    CodeBuildProjectName = aws_ssm_parameter.project_name[each.key].name
    Git2S3OutputBucket   = local.git2s3_bucket
    SourceFileName       = aws_ssm_parameter.source_file_name.name
    TriggerSource        = var.trigger_source
  }
  capabilities = ["CAPABILITY_IAM"]
}
