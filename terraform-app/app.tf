resource "aws_instance" "app" {
  ami = "${var.ami_id}"
  depends_on = ["aws_internet_gateway.default"]
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-app-${var.env_name}"
  }

  vpc_security_group_ids = [ "${aws_security_group.default.id}" ]
}

resource "aws_db_instance" "app" {
  allocated_storage = "${var.rds_storage}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2", "aws_db_parameter_group.force_ssl"]
  engine = "${var.rds_engine}"
  identifier = "${var.name}-${var.env_name}-app"
  instance_class = "${var.rds_instance_class}"
  parameter_group_name = "${var.name}-force-ssl-${var.env_name}"
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  tags {
    client = "${var.client}"
    Name = "${var.name}_${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_eip" "app" {
  instance = "${aws_instance.app.id}"
  vpc      = true
}
