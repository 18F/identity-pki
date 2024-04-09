# TODO: remove this file in a subsequent release, as all of the moves
# should be done and the old references will no longer be needed.

moved {
  from = aws_cloudwatch_log_group.idp_events
  to   = aws_cloudwatch_log_group.log["idp_events"]
}

moved {
  from = aws_cloudwatch_log_group.kms_log
  to   = aws_cloudwatch_log_group.log["idp_kms"]
}

moved {
  from = aws_cloudwatch_log_group.idp_production
  to   = aws_cloudwatch_log_group.log["idp_production"]
}

moved {
  from = aws_cloudwatch_log_group.idp_telephony
  to   = aws_cloudwatch_log_group.log["idp_telephony"]
}

moved {
  from = aws_cloudwatch_log_group.idp_workers
  to   = aws_cloudwatch_log_group.log["idp_workers"]
}

moved {
  from = aws_cloudwatch_log_group.aide
  to   = aws_cloudwatch_log_group.log["aide_aide"]
}

moved {
  from = aws_cloudwatch_log_group.nginx_access_log
  to   = aws_cloudwatch_log_group.log["nginx_access"]
}

moved {
  from = aws_cloudwatch_log_group.nginx_status
  to   = aws_cloudwatch_log_group.log["nginx_status"]
}

moved {
  from = aws_cloudwatch_log_group.passenger_nginx
  to   = aws_cloudwatch_log_group.log["nginx_passenger"]
}

moved {
  from = aws_cloudwatch_log_group.passenger_status
  to   = aws_cloudwatch_log_group.log["nginx_passenger_status"]
}

moved {
  from = aws_cloudwatch_log_group.puma_status
  to   = aws_cloudwatch_log_group.log["nginx_puma_status"]
}

moved {
  from = aws_cloudwatch_log_group.ubuntu_advantage
  to   = aws_cloudwatch_log_group.log["ubuntu_advantage"]
}
