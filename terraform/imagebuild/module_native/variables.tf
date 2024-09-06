locals {
  base_codebuild_name  = var.base_codebuild_name != "" ? (var.base_codebuild_name) : "${var.name}-${var.env_name}-base"
  rails_codebuild_name = var.rails_codebuild_name != "" ? (var.rails_codebuild_name) : "${var.name}-${var.env_name}-rails"

  base_pipeline_name  = var.base_pipeline_name != "" ? (var.base_pipeline_name) : "${var.name}-${var.env_name}-base"
  rails_pipeline_name = var.rails_pipeline_name != "" ? (var.rails_pipeline_name) : "${var.name}-${var.env_name}-rails"

  codepipeline_role_name          = var.codepipeline_role_name != "" ? (var.codepipeline_role_name) : "${var.name}-${data.aws_region.current.name}-${var.env_name}-codepipeline"
  codebuild_role_name             = var.codebuild_role_name != "" ? (var.codebuild_role_name) : "${var.name}-${data.aws_region.current.name}-${var.env_name}-codebuild"
  packer_role_name                = var.packer_role_name != "" ? (var.packer_role_name) : "${var.name}-${data.aws_region.current.name}-${var.env_name}-packer"
  codepipeline_s3_bucket_name     = var.codepipeline_s3_bucket_name != "" ? (var.codepipeline_s3_bucket_name) : "${var.name}-${var.env_name}-codepipeline-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  packer_instance_profile_name    = var.packer_instance_profile_name != "" ? (var.packer_instance_profile_name) : "${var.name}-${data.aws_region.current.name}-${var.env_name}-imagebuild"
  identity_base_image_zip_s3_path = var.identity_base_image_zip_s3_path != "" ? (var.identity_base_image_zip_s3_path) : "18F/identity-base-image/${local.identity_base_git_ref}/18F_identity-base-image.zip"
  identity_base_git_ref           = var.identity_base_git_ref != "" ? (var.identity_base_git_ref) : "main"
}

variable "region" {
  default = "us-west-2"
  type    = string
}

variable "name" {
  default = "login"
  type    = string
}

variable "env_name" {
  type = string
}

variable "account_name" {
  type = string
}

variable "fisma_tag" {
  default = "Q-LG"
  type    = string
}

variable "packer_config" {
  description = <<DESC
Map of key/value pairs for Packer configs consistent in all AMI types in account.
Main number for os_version and ami_filter_name MUST be the same as var.os_number.
DESC
  type        = map(string)
  default = {
    ami_filter_name         = "ubuntu-pro-fips-server/images/hvm-ssd/ubuntu-focal-20.04-amd64*"
    ami_owner_id            = "679593333241",
    berkshelf_version       = "8.0.15"
    chef_version            = "18.4.12" # also passed to CFN as ChefVersion parameter
    data_vol_size           = "200"
    delay_seconds           = "60"
    delete_ami_snapshots    = "false"
    deregister_existing_ami = "false"
    encryption              = "true"
    inspec_version          = "5.22.40"
    instance_type           = "c6i.2xlarge"
    max_attempts            = "50"
    os_version              = "Ubuntu 20.04"
    packer_version          = "1.10.2"
    root_vol_size           = "40"
    ubuntu_major_version    = "20"
  }
}

variable "identity_base_git_ref" {
  description = "git ref to check out"
  type        = string
  default     = ""
}

variable "repo" {
  description = "git repo to check out"
  type        = string
  default     = "identity-base-image"
}

variable "associate_public_ip" {
  description = "associate a public IP"
  type        = bool
  default     = "false"
}

variable "base_codebuild_name" {
  description = "name of base codebuild project"
  type        = string
  default     = ""
}

variable "rails_codebuild_name" {
  description = "name of rails codebuld project"
  type        = string
  default     = ""
}

variable "codebuild_role_name" {
  description = "name of base codebuild iam role"
  type        = string
  default     = ""
}

variable "packer_role_name" {
  description = "name of base packer iam role"
  type        = string
  default     = ""
}

variable "identity_base_image_zip_s3_path" {
  description = "object to poll for source changes"
  type        = string
  default     = ""
}

variable "packer_instance_profile_name" {
  description = "name of instance profile"
  type        = string
  default     = ""
}

variable "git2s3_bucket_name" {
  description = "name of default git2s3 bucket for non_sandbox envs"
  type        = string
  default     = "codesync-identitybaseimage-outputbucket-rlnx3kivn8t8"
}

variable "base_pipeline_name" {
  description = "name of base codepipeline"
  type        = string
  default     = ""
}

variable "rails_pipeline_name" {
  description = "name of rails codepipeline"
  type        = string
  default     = ""
}

variable "codepipeline_role_name" {
  description = "name of base codepipeline iam role"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "the VPC id that is passed to packer for image building"
  type        = string
}

variable "private_subnet_id" {
  description = "the subnet id that is passed to packer for image building"
  type        = string
}

variable "nightly_build_trigger" {
  description = "build AMIs nightly"
  type        = bool
  default     = true
}

variable "source_build_trigger" {
  description = "build AMIs when the s3 source file is updated"
  type        = bool
  default     = true
}

variable "codepipeline_s3_bucket_name" {
  description = "name of bucket to store codepipeline artifacts"
  type        = string
  default     = ""
}

variable "ami_copy_region" {
  description = "The name of a region that Packer copies AMIs to"
  type        = string
  default     = "us-east-1"
}

variable "slack_events_sns_hook_name" {
  description = "Name of SNS topic that send notifications to Slack"
  type        = string
  default     = "slack-events"
}

variable "build_alarms_enable" {
  description = "Enable build alarms"
  type        = bool
  default     = false
}

variable "codebuild_build_timeout" {
  description = "the time codebuild allows a build to run before failing the build"
  type        = string
  default     = "120"
}

variable "ami_lifecycle_enabled" {
  description = "Enable AMI lifecycle cleanup"
  type        = bool
  default     = false
}

variable "ami_regions" {
  description = <<EOM
List of region(s) where AMIs should exist. AMIs are created in us-west-2 and will be
copied to other regions IFF this variable has more than one region listed.
EOM
  type        = list(string)
  default     = ["us-west-2", "us-east-1"]
}

