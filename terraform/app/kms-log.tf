locals {
  kms_arns = concat([module.application_iam_roles.idp_iam_role_arn, module.application_iam_roles.worker_iam_role_arn], var.db_restore_role_arns)
}

module "kms_logging" {

  source = "github.com/18F/identity-terraform//kms_log?ref=b1e3f0deea6604d10789283bad84e28044e41a42"
  #source = "../../../identity-terraform/kms_log"

  env_name                                = var.env_name
  sns_topic_dead_letter_arn               = var.slack_events_sns_hook_arn
  kinesis_shard_count                     = var.kms_log_kinesis_shards
  ec2_kms_arns                            = local.kms_arns
  alarm_sns_topic_arns                    = var.kms_log_alerts_enabled ? [var.slack_events_sns_hook_arn] : []
  kinesis_retention_hours                 = var.kms_log_kinesis_retention_hours
  ct_queue_message_retention_seconds      = var.kms_log_ct_queue_message_retention_seconds
  dynamodb_retention_days                 = var.kms_log_dynamodb_retention_days
  kmslog_lambda_debug                     = var.kms_log_kmslog_lambda_debug
  lambda_identity_lambda_functions_gitrev = var.kms_log_lambda_identity_lambda_functions_gitrev

  lambda_kms_cw_processor_zip      = module.kms_lambda_processors_code.zip_output_path
  cw_processor_memory_size         = var.kms_log_cw_processor_memory_size
  cw_processor_storage_size        = var.kms_log_cw_processor_storage_size
  lambda_kms_ct_processor_zip      = module.kms_lambda_processors_code.zip_output_path
  lambda_kms_event_processor_zip   = module.kms_lambda_processors_code.zip_output_path
  lambda_slack_batch_processor_zip = module.kms_slack_batch_processor_code.zip_output_path
}

resource "null_resource" "kms_lambda_processors_build" {
  provisioner "local-exec" {
    command     = "./scripts/install-deps.sh"
    working_dir = "${path.module}/lambda/kms_lambda_processors"
  }
}

module "kms_lambda_processors_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "lib/kms_monitor/cloudwatch.rb"
  source_dir           = "${path.module}/lambda/kms_lambda_processors/"
  zip_filename         = "${path.module}/lambda/kms_lambda_processors.zip"


  depends_on = [null_resource.kms_lambda_processors_build]
}

module "kms_slack_batch_processor_code" {
  source = "github.com/18F/identity-terraform//null_archive?ref=6cdd1037f2d1b14315cc8c59b889f4be557b9c17"
  #source = "../../../../identity-terraform/null_archive"

  source_code_filename = "kms_slack_batch_processor.py"
  source_dir           = "${path.module}/lambda/kms_slack_batch_processor/"
  zip_filename         = "${path.module}/lambda/kms_slack_batch_processor.zip"
}

module "kms_keymaker_uw2" {
  source = "github.com/18F/identity-terraform//kms_keymaker?ref=cae10655e00dfd9751b5a73f974f9452efab3871"
  #source = "../../../identity-terraform/kms_keymaker"

  env_name      = var.env_name
  ec2_kms_arns  = local.kms_arns
  sqs_queue_arn = module.kms_logging.kms-ct-events-queue
}

module "kms_keymaker_multiregion_primary_uw2" {
  source = "github.com/18F/identity-terraform//kms_keymaker_multiregion_primary?ref=49bc02749966cef8ec7f14c4d181a2d3879721fc"
  #source = "../../../identity-terraform/kms_keymaker_multiregion_primary"

  env_name            = var.env_name
  ec2_kms_arns        = local.kms_arns
  sqs_queue_arn       = module.kms_logging.kms-ct-events-queue
  alarm_sns_topic_arn = var.slack_events_sns_hook_arn
}

module "kms_keymaker_multiregion_replica_ue1" {
  count  = var.replicate_keymaker_key ? 1 : 0
  source = "github.com/18F/identity-terraform//kms_keymaker_multiregion_replica?ref=49bc02749966cef8ec7f14c4d181a2d3879721fc"
  #source = "../../../identity-terraform/kms_keymaker_multiregion_replica"
  providers = {
    aws = aws.use1
  }

  env_name        = var.env_name
  ec2_kms_arns    = local.kms_arns
  sqs_queue_arn   = module.kms_logging.kms-ct-events-queue
  primary_key_arn = module.kms_keymaker_multiregion_primary_uw2.multi_region_primary_key_arn
  # alarm_sns_topic_arn = var.slack_events_sns_hook_arn
}

moved {
  from = module.kms_keymaker_multiregion_replica_ue1
  to   = module.kms_keymaker_multiregion_replica_ue1[0]
}
