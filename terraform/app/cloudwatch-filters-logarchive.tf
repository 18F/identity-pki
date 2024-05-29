# NOTE: Until we've finalized the naming schema for other types of Log Groups,
# including system-based ones (e.g. /var and /srv on appropriate host types)
# and service-based ones, the groups we'll send to the logarchive account(s)
# are noted here, but commented out, so as not to create random S3 paths
# with their current names. They can be uncommented once we've settled on a proper
# organizational structure AND have updated the underlying applications to use
# the new Log Group names/paths in CloudWatch, as these lines refer to the Terraform
# resources and do not have hard-coded values.

##### us-west-2 #####

module "logarchive_uw2" {
  count  = length(var.logarchive_acct_id) != 0 ? 1 : 0
  source = "../modules/logarchive_subscription_filter"
  providers = {
    aws = aws.usw2
  }

  logarchive_acct_id = var.logarchive_acct_id
  log_groups = {
    #"cloudwatch" = flatten([
    #  [for group in aws_cloudwatch_log_group.log : group.name], # cloudwatch-log.tf
    #  aws_cloudwatch_log_group.dns_query_log.name,              # cloudwatch-log.tf
    #  aws_cloudwatch_log_group.elasticache_redis_log.name,      # cloudwatch-log.tf
    #  module.kms_logging.unmatched-log-group,                   # kms-log.tf
    #  module.outboundproxy_uw2.squid_access_log,                # outboundproxy.tf
    #  module.outboundproxy_uw2.squid_cache_log,                 # outboundproxy.tf
    #]),
    #"lambda" = flatten([
    #  module.kms_logging.lambda-log-groups, # kms-log.tf
    #  module.cloudwatch_sli.cw_log_group,   # cloudwatch-slos.tf
    #]),
    #"ssm" = flatten([
    #  module.ssm_uw2.ssm_cmd_logs,     # ssm.tf
    #  module.ssm_uw2.ssm_session_logs, # ssm.tf
    #]),
    #"vpc" = flatten([
    #  module.network_uw2.flow_log_group # net.tf
    #]),
    #"rds" = flatten([
    #  var.apps_enabled == 1 ? (
    #  module.dashboard_aurora_uw2[0].log_groups) : [], # app-aurora.tf
    #  module.idp_aurora_uw2.log_groups,                # idp-aurora.tf
    #  module.worker_aurora_uw2.log_groups,             # worker-aurora.tf
    #])
  }
}

##### us-east-1 #####

module "logarchive_ue1" {
  count = alltrue([
    length(var.logarchive_acct_id) != 0,
    var.enable_us_east_1_infra,
    var.idp_aurora_ue1_enabled,
    var.enable_us_east_1_vpc
  ]) ? 1 : 0
  source = "../modules/logarchive_subscription_filter"
  providers = {
    aws = aws.use1
  }

  logarchive_acct_id = var.logarchive_acct_id
  log_groups = {
    #"cloudwatch" = flatten([
    #  module.outboundproxy_use1[0].squid_access_log, # outboundproxy.tf
    #  module.outboundproxy_use1[0].squid_cache_log,  # outboundproxy.tf
    #]),
    #"ssm" = flatten([
    #  module.ssm_ue1[0].ssm_cmd_logs,     # ssm.tf
    #  module.ssm_ue1[0].ssm_session_logs, # ssm.tf
    #]),
    #"vpc" = flatten([
    #  module.network_use1[0].flow_log_group # net.tf
    #])
    #"rds" = flatten([
    #  module.idp_aurora_ue1[0].log_groups, # idp-aurora.tf
    #])
  }
}
