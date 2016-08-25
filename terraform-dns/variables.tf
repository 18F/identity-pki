variable "access_key" {}
variable "access_key_18f_ent" {}
variable "region" { default = "us-west-2" }
variable "secret_key" {}
variable "secret_key_18f_ent" {}
variable "zone_id" {}

data "terraform_remote_state" "app-tf" {
  backend = "s3"
  config {
    bucket = "login_dot_gov_terraform_state-${var.region}"
    key = "terraform-app/terraform-tf.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-dev" {
  backend = "s3"
  config {
    bucket = "login_dot_gov_terraform_state-${var.region}"
    key = "terraform-app/terraform-dev.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-pt" {
  backend = "s3"
  config {
    bucket = "login_dot_gov_terraform_state-${var.region}"
    key = "terraform-app/terraform-pt.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-qa" {
  backend = "s3"
  config {
    bucket = "login_dot_gov_terraform_state-${var.region}"
    key = "terraform-app/terraform-qa.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "chef" {
  backend = "s3"
  config {
    access_key = "${var.access_key}"
    bucket = "login_dot_gov_terraform_state-${var.region}"
    key = "terraform-chef/terraform.tfstate"
    region = "us-east-1"
  }
}
