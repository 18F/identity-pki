# This file exists for simplifying the process of count-ize-ing RDS/Aurora-related
# resources during/after the IdP DB creation/upkeep. Once we've switched over to the
# post-DMS/BigInt version of the IdP database, this file can be removed entirely.
# Each 'moved' block references where the original resource can be found.


moved {
  from = module.idp_aurora_cloudwatch[0]
  to   = module.idp_aurora_cloudwatch
}

moved {
  from = module.idp_aurora_from_rds[0]
  to   = module.idp_aurora_uw2
}
