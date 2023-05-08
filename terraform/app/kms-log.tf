locals {
  kms_arns = concat([aws_iam_role.idp.arn, aws_iam_role.worker.arn], var.db_restore_role_arns)
}

module "kms_logging" {

  source = "github.com/18F/identity-terraform//kms_log?ref=96b1157d1de012259c72f237a1657f268eed26cb"
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

  lambda_kms_cw_processor_zip    = module.kms_lambda_processors_code.zip_output_path
  lambda_kms_ct_processor_zip    = module.kms_lambda_processors_code.zip_output_path
  lambda_kms_event_processor_zip = module.kms_lambda_processors_code.zip_output_path
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

module "kms_keymaker_uw2" {
  source = "github.com/18F/identity-terraform//kms_keymaker?ref=0f7605a740b27b70d72c134ec1c0cd3568b0e9cd"
  #source = "../../../identity-terraform/kms_keymaker"

  env_name      = var.env_name
  ec2_kms_arns  = local.kms_arns
  sqs_queue_arn = module.kms_logging.kms-ct-events-queue
}

# this key is being supersceded by the multi-region keys below
module "kms_keymaker_ue1" {
  source = "github.com/18F/identity-terraform//kms_keymaker?ref=0f7605a740b27b70d72c134ec1c0cd3568b0e9cd"
  #source = "../../../identity-terraform/kms_keymaker"
  providers = {
    aws = aws.use1
  }

  env_name      = var.env_name
  ec2_kms_arns  = local.kms_arns
  sqs_queue_arn = module.kms_logging.kms-ct-events-queue
}

module "kms_keymaker_multiregion_primary_uw2" {
  source = "github.com/18F/identity-terraform//kms_keymaker_multiregion_primary?ref=0f7605a740b27b70d72c134ec1c0cd3568b0e9cd"
  #source = "../../../identity-terraform/kms_keymaker_multiregion_primary"

  env_name      = var.env_name
  ec2_kms_arns  = local.kms_arns
  sqs_queue_arn = module.kms_logging.kms-ct-events-queue
}

module "kms_keymaker_multiregion_replica_ue1" {
  source = "github.com/18F/identity-terraform//kms_keymaker_multiregion_replica?ref=0f7605a740b27b70d72c134ec1c0cd3568b0e9cd"
  #source = "../../../identity-terraform/kms_keymaker_multiregion_replica"
  providers = {
    aws = aws.use1
  }

  env_name        = var.env_name
  ec2_kms_arns    = local.kms_arns
  sqs_queue_arn   = module.kms_logging.kms-ct-events-queue
  primary_key_arn = module.kms_keymaker_multiregion_primary_uw2.multi_region_primary_key_arn
}
