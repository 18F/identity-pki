variable "region" {
  description = "AWS region, used for S3 bucket names"
}

variable "tf_dir" {
  description = "directory to terraform out of identity-devops"
}

variable "gitref" {
  description = "gitref to check out before deploying"
}

variable "auto_tf_vpc_id" {
  description = "VPC id for this to run in"
}

variable "auto_tf_subnet1_id" {
  description = "subnet1 id"
}

variable "auto_tf_subnet2_id" {
  description = "subnet2 id"
}

variable "auto_tf_role_arn" {
  description = "auto_tf role ARN"
}

variable "auto_tf_sg_id" {
  description = "auto_tf security group id"
}

variable "auto_tf_pipeline_role_arn" {
  description = "pipeline role arn"
}

variable "auto_tf_bucket_id" {
  description = "bucket where artifacts are stored"
}

variable "env_name" {
  description = "environment to deploy to"
  default = ""
}

variable "account" {
  description = "account to deploy to"
}

# this is a github personal access token that can be used to pull the
# identity-devops repo.  You can create it like so:  https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token
# NOTE:  these s3 objects need to be uploaded with --content-type text/plain
data "aws_s3_bucket_object" "identity_devops_oauthkey" {
  bucket = "login-gov.secrets.${data.aws_caller_identity.current.account_id}-${var.region}"
  key    = "common/identity_devops_oauthkey"
}
