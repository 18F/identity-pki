provider "aws" {
  region = "${var.region}"
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

resource "aws_route53_record" "redis" {
  zone_id = "${aws_route53_zone.internal.zone_id}"
  name = "redis"

  type = "CNAME"
  ttl = "300"
  records = ["${aws_elasticache_cluster.idp.cache_nodes.0.address}"]
}


# This policy can be used to allow anybody to join the role
data "aws_iam_policy_document" "assume_role_from_vpc" {
  statement {
    sid = "allowVPC"
    actions = [
      "sts:AssumeRole"
    ]
    principals = {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


data "aws_caller_identity" "current" {}

