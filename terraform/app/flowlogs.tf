##########################################
# Get flow logs going into cloudwatch

moved {
  from = aws_flow_log.flow_log
  to   = module.network_usw2.aws_flow_log.flow_log
}

moved {
  from = aws_cloudwatch_log_group.flow_log_group
  to   = module.network_usw2.aws_cloudwatch_log_group.flow_log_group
}