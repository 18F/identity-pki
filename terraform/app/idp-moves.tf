# This file exists for simplifying the process of count-ize-ing RDS/Aurora-related
# resources during/after the IdP DB creation/upkeep. Once we've switched over to the
# post-DMS/BigInt version of the IdP database, this file can be removed entirely.
# This assumes that the environment has var.idp_aurora_enabled set to 'true'.
# Each 'moved' block references where the original resource can be found.

moved {
  from = module.idp_aurora_from_rds[0].aws_db_parameter_group.aurora[0]
  to   = module.idp_rds_usw2.aws_db_parameter_group.aurora[0]
}

moved {
  from = module.idp_aurora_from_rds[0].aws_rds_cluster_parameter_group.aurora[0]
  to   = module.idp_rds_usw2.aws_rds_cluster_parameter_group.aurora[0]
}

moved {
  from = module.worker_aurora_uw2[0]
  to   = module.worker_aurora_uw2
}

moved {
  from = module.worker_aurora_uw2_cloudwatch[0]
  to   = module.worker_aurora_uw2_cloudwatch
}
