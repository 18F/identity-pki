variable "region" {
  default = "us-west-2"
}

variable "ami_types" {
  description = "Names of the types of AMIs being created (base/rails by default)."
  type        = list(string)
  default     = [
    "base",
    "rails"
  ]
}

variable "image_build_private_cidr" {
  description = "CIDR block for the public subnet 1"
  type        = string
  default     = "10.0.11.0/24"
}

variable "image_build_public_cidr" {
  description = "CIDR block for the public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "image_build_vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/19"
}

variable "artifact_bucket" {
  default = "login-gov-public-artifacts-us-west-2"
}

variable "code_branch" {
  description = "Name of the identity-base-image branch used for builds/pipelines."
  type        = string
  default     = "main"
}

variable "packer_config" {
  description = "Map of key/value pairs for Packer configs consistent in all AMI types."
  type = map(string)
  default = {
    encryption              = "true"
    root_vol_size           = "40"
    data_vol_size           = "100"
    deregister_existing_ami = "false"
    delete_ami_snapshots    = "false"
    chef_version            = "15.10.12"
    os_version              = "Ubuntu 18.04"
    ami_owner_id            = "679593333241",
    ami_filter_name         = "ubuntu-pro-fips/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-202-eaa0674e-0ac1-4b3d-9076-ec16636760e8-ami-0c3a78fa8fb3b0ed8.4"
  }
}

variable "trigger_source" {
  description = <<DESC
Which service can trigger the CodePipeline which runs the ImageBuild CodeBuild project.
Options are 'S3', 'CloudWatch', or 'Both'.
DESC
  type = string
  default = "Both"
}