variable "bucket" { default = "login_dot_gov_tf_state" }
variable "region" { default = "us-west-2" }

data "terraform_remote_state" "app-tf" {
  backend = "s3"
  config {
    bucket = "${var.bucket}"
    key = "terraform-app/terraform-tf.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-dev" {
  backend = "s3"
  config {
    bucket = "${var.bucket}"
    key = "terraform-app/terraform-dev.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-int" {
  backend = "s3"
  config {
    bucket = "${var.bucket}"
    key = "terraform-app/terraform-int.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-pt" {
  backend = "s3"
  config {
    bucket = "${var.bucket}"
    key = "terraform-app/terraform-pt.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-qa" {
  backend = "s3"
  config {
    bucket = "${var.bucket}"
    key = "terraform-app/terraform-qa.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "app-staging" {
  backend = "s3"
  config {
    bucket = "${var.bucket}"
    key = "terraform-app/terraform-staging.tfstate"
    region = "us-east-1"
  }
}
