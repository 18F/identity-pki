data "aws_iam_account_alias" "current" {}

data "aws_s3_bucket_object" "git2s3_output_bucket" {
  bucket = var.artifact_bucket
  key    = "git2s3/OutputBucketName"
}

resource "aws_cloudformation_stack" "image_network_stack" {
  name          = "login-image-creation"
  template_body = file("${path.module}/login-vpc-image-build.template")
  parameters    = {
    PrivateSubnet1CIDR = var.image_build_private_cidr
    PublicSubnet1CIDR  = var.image_build_public_cidr
    VPCCIDR            = var.image_build_vpc_cidr
  }
}

resource "aws_cloudformation_stack" "image_codebuild_stack" {
  for_each = toset(var.ami_types)

  name          = join("", ["CodeBuild-Image", title(each.key), "Role"])
  template_body = file("${path.module}/login-codebuild-image.template")
  parameters    = {
    AccountAlias     = trim(data.aws_iam_account_alias.current.account_alias, "login-")
    NetworkStackName = aws_cloudformation_stack.image_network_stack.name
    ProjectName      = "login-image-${each.key}"
    RoleName         = each.key
    SourceFileName   = "18F/identity-base-image/branch/master/18F_identity-base-image_branch_master.zip"
    Git2S3OutputBucket = data.aws_s3_bucket_object.git2s3_output_bucket.body
  }
}

resource "aws_cloudformation_stack" "image_codepipeline_stack" {
  for_each = toset(var.ami_types)

  name          = join("", ["CodePipeline-Image", title(each.key), "Role"])
  template_body = file("${path.module}/login-codepipeline-image.template")
  parameters    = {
    CodeBuildStackName = aws_cloudformation_stack.image_codebuild_stack[each.key].name
    Git2S3OutputBucket = data.aws_s3_bucket_object.git2s3_output_bucket.body
  }
}
