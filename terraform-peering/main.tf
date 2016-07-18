provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}


resource "aws_route" "app" {
  route_table_id = "${terraform_remote_state.chef.output.aws_vpc_route_table_id}"
  destination_cidr_block = "${terraform_remote_state.app.output.aws_vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.default.id}"
}

resource "aws_route" "chef" {
  route_table_id = "${terraform_remote_state.app.output.aws_vpc_route_table_id}"
  destination_cidr_block = "${terraform_remote_state.chef.output.aws_vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.default.id}"
}

resource "aws_vpc_peering_connection" "default" {
  vpc_id        = "${terraform_remote_state.app.output.aws_vpc_id}"
  peer_vpc_id   = "${terraform_remote_state.chef.output.aws_vpc_id}"
  peer_owner_id = "${var.account_id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }

  auto_accept = true
}

resource "terraform_remote_state" "app" {
  backend = "s3"
  config {
    bucket = "login_dot_gov_terraform_state-${var.region}-${var.env_name}"
    key = "terraform-app/.terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "terraform_remote_state" "chef" {
  backend = "s3"
  config {
    bucket = "login_dot_gov_terraform_state-${var.region}-${var.env_name}"
    key = "terraform-chef/.terraform/terraform.tfstate"
    region = "us-east-1"
  }
}
