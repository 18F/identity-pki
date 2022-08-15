variable "region" {
  default = "us-west-2"
}

variable "fisma_tag" {
  default = "Q-LG"
}

variable "ami_types" {
  description = "Names of the types of AMIs being created (base/rails by default)."
  type        = list(string)
  default = [
    "base",
    "rails"
  ]
}

variable "image_build_nat_eip" {
  description = <<EOM
Elastic IP address for the NAT gateway.
Must already be allocated via other means.
EOM
  type        = string
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
  type        = map(string)
  default = {
    encryption              = "true"
    root_vol_size           = "40"
    data_vol_size           = "100"
    deregister_existing_ami = "false"
    delete_ami_snapshots    = "false"
    chef_version            = "17.5.22" # also passed to CloudFormation as ChefVersion parameter.
    os_version              = "Ubuntu 18.04"
    ami_owner_id            = "679593333241",
    ami_filter_name         = "ubuntu-pro-fips-server/images/hvm-ssd/ubuntu-focal-18.04-amd64*"
  }
}

variable "trigger_source" {
  description = <<DESC
Which service can trigger the CodePipeline which runs the ImageBuild CodeBuild project.
Options are 'S3', 'CloudWatch', or 'Both'.
DESC
  type        = string
  default     = "Both"
}

variable "packer_version" {
  description = <<DESC
REQUIRED. Packer version used in buildspec.yml file from identity-base-image repo.
Passed into CloudFormation template as PackerVersion parameter.
DESC
  type        = string
  default     = "1.7.2"
}

variable "berkshelf_version" {
  description = <<DESC
REQUIRED. Berkshelf version used in buildspec.yml file from identity-base-image repo.
Passed into CloudFormation template as BerkshelfVersion parameter.
DESC
  type        = string
  default     = "7.1.0"
}

variable "expire_associated_in_days" {
  description = "Number of days to expire an AMI that has been used."
  type        = string
  default     = "30"
}

variable "expire_unassociated_in_days" {
  description = "Number of days to expire an AMI that has not been used"
  type        = string
  default     = "7"
}
