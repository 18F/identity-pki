data "aws_iam_account_alias" "current" {}

data "aws_s3_bucket_object" "git2s3_output_bucket" {
  bucket = var.artifact_bucket
  key    = "git2s3/OutputBucketName"
}

locals {
  aws_alias = trimprefix(data.aws_iam_account_alias.current.account_alias, "login-")
  git2s3_bucket = trimspace(data.aws_s3_bucket_object.git2s3_output_bucket.body)
}

resource "aws_cloudformation_stack" "image_network_stack" {
  name          = "login-image-creation"
  template_body = file("${path.module}/login-vpc-image-build.template")
  parameters    = {
    PrivateSubnet1CIDR = var.image_build_private_cidr
    PublicSubnet1CIDR  = var.image_build_public_cidr
    VPCCIDR            = var.image_build_vpc_cidr
  }
  capabilities = ["CAPABILITY_IAM"]
}

resource "aws_s3_bucket_object" "packer_config" {
  for_each = toset(var.ami_types)

  bucket       = var.artifact_bucket
  key          = "packer_config/${local.aws_alias}/${each.key}.18.json"
  content      = <<JSON
{
  "aws_access_key": "",
  "aws_secret_key": "",
  "aws_region": "${var.region}",
  "encryption": "${var.packer_config["encryption"]}",
  "root_vol_size": "${var.packer_config["root_vol_size"]}",
  "data_vol_size": "${var.packer_config["data_vol_size"]}",
  "security_group_id": "${aws_cloudformation_stack.image_network_stack.outputs["PublicSecurityGroupId"]}",
  "vpc_id": "${aws_cloudformation_stack.image_network_stack.outputs["VPCID"]}",
  "subnet_id": "${aws_cloudformation_stack.image_network_stack.outputs["PublicSubnet1ID"]}",
  "deregister_existing_ami": "${var.packer_config["deregister_existing_ami"]}",
  "delete_ami_snapshots": "${var.packer_config["delete_ami_snapshots"]}",
  "ami_name": "login.gov ${each.key} role hardened image ${var.packer_config["os_version"]}",
  "ami_description": "CIS hardened image based on ${var.packer_config["os_version"]}",
  "chef_role": "${each.key}",
  "chef_version": "${var.packer_config["chef_version"]}",
  "os_version": "${var.packer_config["os_version"]}",
  "ami_owner_id": "${var.packer_config["ami_owner_id"]}",
  "ami_filter_name": "${var.packer_config["ami_filter_name"]}"
}
JSON
  content_type = "text/plain"
}

resource "aws_cloudformation_stack" "image_codebuild_stack" {
  for_each = toset(var.ami_types)

  name          = join("", ["CodeBuild-Image", title(each.key), "Role"])
  template_body = file("${path.module}/login-codebuild-image.template")
  parameters    = {
    AccountAlias       = local.aws_alias
    NetworkStackName   = aws_cloudformation_stack.image_network_stack.name
    ProjectName        = "login-image-${each.key}"
    RoleName           = each.key
    SourceFileName     = "18F/identity-base-image/branch/main/18F_identity-base-image_branch_main.zip"
    Git2S3OutputBucket = local.git2s3_bucket
  }
  capabilities = ["CAPABILITY_IAM"]
}

resource "aws_cloudformation_stack" "image_codepipeline_stack" {
  for_each = toset(var.ami_types)

  name          = join("", ["CodePipeline-Image", title(each.key), "Role"])
  template_body = file("${path.module}/login-codepipeline-image.template")
  parameters    = {
    CodeBuildStackName = aws_cloudformation_stack.image_codebuild_stack[each.key].name
    Git2S3OutputBucket = local.git2s3_bucket
    TriggerSource      = var.trigger_source
  }
  capabilities = ["CAPABILITY_IAM"]
}
