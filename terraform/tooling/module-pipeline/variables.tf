variable "region" {
  description = "AWS region, used for S3 bucket names"
}

variable "state_bucket_region" {
  description = "region of the terraform state bucket"
  default     = "us-west-2"
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

variable "auto_tf_subnet_id" {
  description = "subnet id"
}

variable "auto_tf_subnet_arn" {
  description = "subnet arn"
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
  default     = ""
}

variable "recycletest_env_name" {
  description = "environment to recycle/test"
  default     = ""
}

variable "recycletest_domain" {
  description = "DNS domain used for testing"
  default     = ""
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

# This bundle is updated with bin/terraform-bundle.sh.
# If a file in identity-devops/.tfbundle exists, the contents of that file will
# be read in instead of this default value.  This lets you have a custom tfbundle exist
# on a branch so you can try out new providers or terraform versions, or lag behind
# if you need to as well.
# For example:  echo 'terraform_v1.1.3-bundle2022012018_linux_amd64.zip' > .tfbundle
variable "tfbundle" {
  description = "default name of the tfbundle that you want the system to deploy with in the auto_tf_bucket"
  default     = "terraform_v1.1.3-bundle2022032314_linux_amd64.zip"
}

variable "events_sns_topic" {
  description = "name of the sns topic to send events to"
  default     = "slack-otherevents"
}

variable "enable_autotf_alarms" {
  description = "enable the autotf alarms"
  default     = false
}
