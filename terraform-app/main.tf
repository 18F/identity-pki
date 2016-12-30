provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_db_subnet_group" "default" {
  name = "${var.name}-db-${var.env_name}"
  description = "${var.env_name} subnet group for login.gov"
  subnet_ids = ["${aws_subnet.db1.id}", "${aws_subnet.db2.id}"]

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }
}

resource "aws_db_parameter_group" "force_ssl" {
  name = "${var.name}-force-ssl-${var.env_name}"
  family = "postgres9.5"

  parameter {
    name = "rds.force_ssl"
    value = "1"
    apply_method = "pending-reboot"
  }
}
