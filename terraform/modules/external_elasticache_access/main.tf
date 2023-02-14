resource "aws_lb" "elasticache_nlb" {
  name               = "${var.name}-ec-${var.cluster_name}-nlb-${var.env_name}"
  load_balancer_type = "network"
  internal           = false
  subnets            = var.public_subnet_ids
}

resource "aws_lb_listener" "elasticache_listener" {
  load_balancer_arn = aws_lb.elasticache_nlb.arn

  port     = "6379"
  protocol = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elasticache_tg.arn
  }

  depends_on = [
    aws_lb_target_group.elasticache_tg
  ]
}

resource "aws_lb_target_group" "elasticache_tg" {
  name        = "${var.name}-ec-${var.cluster_name}-tg-${var.env_name}"
  port        = "6379"
  target_type = "ip"
  protocol    = "TCP"
  vpc_id      = var.vpc_id
}

data "aws_network_interfaces" "elasticache_eni_list" {
  filter {
    name   = "subnet-id"
    values = var.data_subnet_ids
  }
  filter {
    name   = "description"
    values = [for cluster in var.clusters : "ElastiCache ${cluster}"]
  }
}

data "aws_network_interface" "cluster_enis" {
  for_each = toset(data.aws_network_interfaces.elasticache_eni_list.ids)
  id       = each.key
}

resource "aws_lb_target_group_attachment" "elasticache" {
  for_each         = data.aws_network_interface.cluster_enis
  target_group_arn = aws_lb_target_group.elasticache_tg.arn
  target_id        = each.value.private_ip

  depends_on = [
    aws_lb_target_group.elasticache_tg
  ]
}
