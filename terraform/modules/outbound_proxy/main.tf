data "aws_caller_identity" "current" {
}

data "aws_network_interface" "obproxy" {
  count = length(var.proxy_subnet_ids)

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.obproxy.arn_suffix}"]
  }
  filter {
    name   = "subnet-id"
    values = ["${element(var.proxy_subnet_ids, count.index)}"]
  }

  depends_on = [
    aws_lb.obproxy
  ]
}
