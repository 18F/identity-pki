##########################################
# Get flow logs going into cloudwatch

resource "aws_flow_log" "flow_log" {
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  iam_role_arn    = module.application_iam_roles.flow_role_iam_role_arn
  vpc_id          = aws_vpc.default.id
  traffic_type    = "ALL"
}

resource "aws_cloudwatch_log_group" "flow_log_group" {
  name = "${var.env_name}_flow_log_group"
}