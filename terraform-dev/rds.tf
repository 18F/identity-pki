resource "aws_db_instance" "default" {
  allocated_storage = "${var.rds_storage}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db"]
  engine = "${var.rds_engine}"
  identifier = "${var.rds_identifier}"
  instance_class = "${var.rds_instance_class}"
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_db_subnet_group" "default" {
  name = "login-dev-subnet-group"
  description = "Dev env subnet group for login.gov"
  subnet_ids = ["${aws_subnet.db1.id}", "${aws_subnet.db2.id}"]

  tags {
    client = "${var.client}"
    Name = "${var.name}"
  }
}
