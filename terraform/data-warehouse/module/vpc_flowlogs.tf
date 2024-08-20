resource "aws_flow_log" "flow_log" {
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  iam_role_arn    = aws_iam_role.flow_role.arn
  vpc_id          = aws_vpc.analytics_vpc.id
  traffic_type    = "ALL"
}

module "vpc_flow_cloudwatch_filters" {
  source = "github.com/18F/identity-terraform//vpc_flow_cloudwatch_filters?ref=06c8ddd069ed1eea84785033f87b7560eaf0ef6f"
  #source     = "../../../identity-terraform/vpc_flow_cloudwatch_filters"
  depends_on = [aws_flow_log.flow_log]

  env_name      = var.env_name
  alarm_actions = local.low_priority_alarm_actions
  vpc_flow_rejections_internal_fields = {
    action  = "action=REJECT"
    srcAddr = "srcAddr=172.16.* || srcAddr=100.106.*"
  }
  vpc_flow_rejections_unexpected_fields = {
    action  = "action=REJECT"
    srcAddr = "srcAddr=172.16.* || srcAddr=100.106.*"
    dstAddr = "dstAddr!=192.88.99.255"
    srcPort = "srcPort!=26 && srcPort!=443 && srcPort!=3128 && srcPort!=5044"
  }
}
