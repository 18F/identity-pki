provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

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

resource "aws_instance" "worker" {
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

resource "aws_eip" "app" {
  instance = "${aws_instance.app.id}"
  vpc      = true
}

resource "aws_elasticache_cluster" "app" {
  cluster_id = "login-ecache-${var.env_name}"
  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis3.2"
  port = 6379
  security_group_ids = ["${aws_security_group.cache.id}"]
  subnet_group_name = "${aws_elasticache_subnet_group.app.name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-elasticache_cluster-${var.env_name}"
  }
}
