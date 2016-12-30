resource "aws_instance" "idp" {
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

resource "aws_instance" "idp_worker" {
  ami = "${var.ami_id}"
  depends_on = ["aws_internet_gateway.default"]
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.app.id}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-worker-${var.env_name}"
  }

  vpc_security_group_ids = [ "${aws_security_group.default.id}" ]
}

resource "aws_db_instance" "idp" {
  allocated_storage = "${var.rds_storage}"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  depends_on = ["aws_security_group.db", "aws_subnet.db1", "aws_subnet.db2", "aws_db_parameter_group.force_ssl"]
  engine = "${var.rds_engine}"
  identifier = "${var.name}-${var.env_name}-idp"
  instance_class = "${var.rds_instance_class}"
  parameter_group_name = "${var.name}-force-ssl-${var.env_name}"
  password = "${var.rds_password}"
  username = "${var.rds_username}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-${var.env_name}"
  }

  vpc_security_group_ids = ["${aws_security_group.db.id}"]
}

resource "aws_eip" "idp" {
  instance = "${aws_instance.idp.id}"
  vpc      = true
}

resource "aws_elasticache_cluster" "idp" {
  cluster_id = "login-ecache-${var.env_name}"
  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis3.2"
  port = 6379
  security_group_ids = ["${aws_security_group.cache.id}"]
  subnet_group_name = "${aws_elasticache_subnet_group.idp.name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-elasticache_cluster-${var.env_name}"
  }
}
