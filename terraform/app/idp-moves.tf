# This file exists for simplifying the process of count-ize-ing the
# IdP RDS instance creation/upkeep. Once we've completely
# turned down RDS everywhere, this file can be removed entirely.
# This assumes that the corresponding environment has var.idp_use_rds set to 'true'.
# Each 'moved' block references where the original resource can be found.

# idp.tf:1
moved {
  from = aws_db_instance.idp
  to   = aws_db_instance.idp[0]
}

# idp.tf:60
moved {
  from = module.idp_cloudwatch_rds
  to   = module.idp_cloudwatch_rds[0]
}

# idp.tf:161
moved {
  from = aws_route53_record.idp-postgres
  to   = aws_route53_record.idp-postgres[0]
}

# cloudwatch-dashboard-idp-general.tf:29
moved {
  from = module.rds_dashboard_idp
  to   = module.rds_dashboard_idp[0]
}

