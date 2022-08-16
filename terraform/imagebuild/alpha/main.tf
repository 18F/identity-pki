provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["917793222841"] # require login-alpha
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

variable "code_branch" {
  default = "main"
}

#### uncomment to test deployments in login-alpha #####
module "main" {
  source = "../module"

  trigger_source      = "CloudWatch"
  code_branch         = var.code_branch
  image_build_nat_eip = "54.70.214.142" # TODO: make this programmable

  # comment out/remove once 20.04 is standard
  os_number = "20"
  packer_config = {
    encryption              = "true"
    root_vol_size           = "40"
    data_vol_size           = "100"
    deregister_existing_ami = "false"
    delete_ami_snapshots    = "false"
    chef_version            = "17.5.22"
    os_version              = "Ubuntu 20.04"
    ami_owner_id            = "679593333241",
    ami_filter_name         = "ubuntu-pro-fips-server/images/hvm-ssd/ubuntu-focal-20.04-amd64*"
  }
}
