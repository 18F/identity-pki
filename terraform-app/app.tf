resource "aws_db_instance" "default" {
  allocated_storage = "${var.rds_storage_app}"
  apply_immediately = true
  count = "${var.apps_enabled}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2"]
  engine = "${var.rds_engine}"
  engine_version = "${var.rds_engine_version}"
  identifier = "${var.name}-${var.env_name}"
  instance_class = "${var.rds_instance_class}"
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  # change this to true to allow upgrading engine versions
  allow_major_version_upgrade = false

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}-app"
  }

  # enhanced monitoring
  monitoring_interval = "${var.rds_enhanced_monitoring_enabled ? 60 : 0}"
  monitoring_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.rds_monitoring_role_name}"

  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  # If you want to destroy your database, comment this block out
  lifecycle {
    prevent_destroy = true

    # we set the password by hand so it doesn't end up in the state file
    ignore_changes = ["password"]
  }
}

output "app_db_endpoint" {
  value = "${element(concat(aws_db_instance.default.*.endpoint, list("")), 0)}"
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

resource "aws_route53_record" "app_internal" {
  count = "${var.apps_enabled * var.alb_enabled}"
  name = "app.login.gov.internal"
  zone_id = "${aws_route53_zone.internal.zone_id}"
  records = ["${aws_alb.app.dns_name}"]
  ttl = "300"
  type = "CNAME"
}

resource "aws_route53_record" "app_external" {
  count = "${var.apps_enabled * var.alb_enabled}"
  name = "app.${var.env_name}.${var.root_domain}"
  zone_id = "${var.route53_id}"
  records = ["${aws_alb.app.dns_name}"]
  ttl = "300"
  type = "CNAME"
}

resource "aws_route53_record" "c_dash" {
  count = "${var.apps_enabled ? 1 : 0}"
  name = "dashboard.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp" {
  count = "${var.apps_enabled}"
  name = "sp.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp_oidc_sinatra" {
  count = "${var.apps_enabled}"
  name = "sp-oidc-sinatra.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp_rails" {
  count = "${var.apps_enabled}"
  name = "sp-rails.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "c_sp_sinatra" {
  count = "${var.apps_enabled}"
  name = "sp-sinatra.${var.env_name}.${var.root_domain}"
  records = ["app.${var.env_name}.${var.root_domain}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${var.route53_id}"
}

resource "aws_route53_record" "postgres" {
  count = "${var.apps_enabled}"
  name = "postgres"
  records = ["${replace(aws_db_instance.default.endpoint,":5432","")}"]
  ttl = "300"
  type = "CNAME"
  zone_id = "${aws_route53_zone.internal.zone_id}"
}
