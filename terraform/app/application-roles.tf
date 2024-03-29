# Create IAM roles and policies used by the application
module "application_iam_roles" {
  source                         = "../modules/application_iam_roles"
  env_name                       = var.env_name
  region                         = var.region
  apps_enabled                   = var.apps_enabled
  identity_sms_aws_account_id    = var.identity_sms_aws_account_id
  app_secrets_bucket_name_prefix = var.app_secrets_bucket_name_prefix
  escrow_bucket_arn              = aws_s3_bucket.escrow.arn
  escrow_bucket_id               = aws_s3_bucket.escrow.id
  cloudfront_oai_iam_arn         = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
  idp_doc_capture_arn            = aws_s3_bucket.idp_doc_capture.arn
  kinesis_bucket_arn             = module.kinesis-firehose.kinesis_firehose_stream_bucket.arn
  kinesis_kms_key_arn            = module.kinesis-firehose.kinesis_firehose_stream_bucket_kms_key.arn
  gitlab_env_runner_role_arn     = try(module.env-runner[0].runner_role_arn, null)
  slack_events_sns_hook_arn      = var.slack_alarms_sns_hook_arn
  slack_events_sns_hook_arn_use1 = var.slack_alarms_sns_hook_arn_use1
  root_domain                    = var.root_domain
  gitlab_enabled                 = var.gitlab_enabled
  usps_updates_sqs_arn           = try(module.usps_updates[0].sqs_arn, null)
  idp_doc_capture_kms_arn        = aws_kms_key.idp_doc_capture.arn
  pivcac_route53_zone_id         = aws_route53_zone.pivcac_zone.id
  enable_usps_status_updates     = var.enable_usps_status_updates
  identity_sms_iam_role_name_idp = var.identity_sms_iam_role_name_idp
  ssm_policy                     = module.ssm_uw2.ssm_access_role_policy
  ssm_access_enabled             = var.ssm_access_enabled
  ipv4_secondary_cidr            = module.network_uw2.secondary_cidr
  create_ue1_ssm_policy          = var.enable_us_east_1_infra
  ssm_kms_key_ue1                = var.enable_us_east_1_infra ? module.ssm_ue1[0].ssm_kms_arn : ""

  depends_on = [
    module.ssm_uw2,
    module.ssm_ue1
  ]
}

moved {
  from = aws_iam_role.idp
  to   = module.application_iam_roles.aws_iam_role.idp
}

moved {
  from = aws_iam_role.migration
  to   = module.application_iam_roles.aws_iam_role.migration
}

moved {
  from = aws_iam_role.worker
  to   = module.application_iam_roles.aws_iam_role.worker
}

moved {
  from = aws_iam_role.obproxy
  to   = module.application_iam_roles.aws_iam_role.obproxy
}

moved {
  from = aws_iam_role.app[0]
  to   = module.application_iam_roles.aws_iam_role.app[0]
}

moved {
  from = aws_iam_role.pivcac
  to   = module.application_iam_roles.aws_iam_role.pivcac
}

moved {
  from = aws_iam_role.base-permissions
  to   = module.application_iam_roles.aws_iam_role.base-permissions
}

moved {
  from = aws_iam_role.citadel-client
  to   = module.application_iam_roles.aws_iam_role.citadel-client
}

moved {
  from = aws_iam_role.flow_role
  to   = module.application_iam_roles.aws_iam_role.flow_role
}

moved {
  from = aws_iam_role.service-discovery
  to   = module.application_iam_roles.aws_iam_role.service-discovery
}

moved {
  from = aws_iam_role.application-secrets
  to   = module.application_iam_roles.aws_iam_role.application-secrets
}

moved {
  from = aws_iam_role.events_log_glue_crawler
  to   = module.application_iam_roles.aws_iam_role.events_log_glue_crawler
}

moved {
  from = aws_iam_policy.escrow_write
  to   = module.application_iam_roles.aws_iam_policy.escrow_write
}