resource "aws_db_instance" "default" {
  allocated_storage = "${var.rds_storage}"
  count = "${var.apps_enabled == true ? 1 : 0}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2"]
  engine = "${var.rds_engine}"
  identifier = "${var.name}-${var.env_name}"
  instance_class = "${var.rds_instance_class}"
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_db_subnet_group" "default" {
  description = "${var.env_name} env subnet group for login.gov"
  name = "${var.name}-db-${var.env_name}"
  subnet_ids = ["${aws_subnet.db1.id}", "${aws_subnet.db2.id}"]

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }
}

resource "aws_route53_record" "postgres" {
  count = "${var.apps_enabled == true ? 1 : 0}"
  name = "postgres"
  records = ["${replace(aws_db_instance.default.endpoint,":5432","")}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.internal.zone_id}"
}
