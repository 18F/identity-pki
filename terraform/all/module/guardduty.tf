# Terraform providers cannot be iterated on (via count/for_each),
# so we need a separate module for each region, at least for now.
# More info:
# https://github.com/hashicorp/terraform/issues/24476
# https://github.com/hashicorp/terraform/issues/25244

# For shipping GuardDuty logs to SOC, you MUST contact the SOCaaS team
# to allow this account permission to the destination ARN. See:
# https://github.com/18F/identity-devops/wiki/Runbook:-GSA-SOC-as-a-Service-(SOCaaS)#cloudwatch-shipping-important-note

## us-west-2

module "guardduty_usw2" {
  source = "github.com/18F/identity-terraform//guardduty?ref=53fd4809b95dfab7e7e10b6ca080f6c89bda459b"
  #source = "../../../../identity-terraform/guardduty"
  providers = {
    aws = aws.usw2
  }

  bucket_name_prefix   = local.bucket_name_prefix
  log_group_id         = var.guardduty_log_group_id
  finding_freq         = var.guardduty_finding_freq
  s3_enable            = var.guardduty_s3_enable
  k8s_audit_enable     = var.guardduty_k8s_audit_enable
  ec2_ebs_enable       = var.guardduty_ec2_ebs_enable
  log_bucket_name      = module.tf-state.s3_access_log_bucket
  inventory_bucket_arn = module.tf-state.inventory_bucket_arn
}

module "guardduty_logs_to_soc_usw2" {
  count      = var.guardduty_usw2_soc_enabled ? 1 : 0
  depends_on = [module.guardduty_usw2]
  providers = {
    aws = aws.usw2
  }
  source                              = "../../modules/log_ship_to_soc"
  region                              = var.region
  cloudwatch_subscription_filter_name = "gd-logs-to-soc"
  cloudwatch_log_group_name = {
    (var.guardduty_log_group_id) = ""
  }
  env_name            = "gd-${var.region}"
  soc_destination_arn = "arn:aws:logs:${var.region}:752281881774:destination:elp-guardduty-lg"
}

## us-east-1

module "guardduty_use1" {
  source = "github.com/18F/identity-terraform//guardduty?ref=53fd4809b95dfab7e7e10b6ca080f6c89bda459b"
  #source = "../../../../identity-terraform/guardduty"
  providers = {
    aws = aws.use1
  }

  region               = "us-east-1"
  bucket_name_prefix   = local.bucket_name_prefix
  log_group_id         = var.guardduty_log_group_id
  finding_freq         = var.guardduty_finding_freq
  s3_enable            = var.guardduty_s3_enable
  k8s_audit_enable     = var.guardduty_k8s_audit_enable
  ec2_ebs_enable       = var.guardduty_ec2_ebs_enable
  log_bucket_name      = module.tf-state-use1.s3_access_log_bucket
  inventory_bucket_arn = module.tf-state-use1.inventory_bucket_arn
}

module "guardduty_logs_to_soc_use1" {
  count      = var.guardduty_use1_soc_enabled ? 1 : 0
  depends_on = [module.guardduty_use1]
  providers = {
    aws = aws.use1
  }
  source                              = "../../modules/log_ship_to_soc"
  region                              = "us-east-1"
  cloudwatch_subscription_filter_name = "gd-logs-to-soc"
  cloudwatch_log_group_name = {
    (var.guardduty_log_group_id) = ""
  }
  env_name            = "gd-us-east-1"
  soc_destination_arn = "arn:aws:logs:us-east-1:752281881774:destination:elp-guardduty-lg"
}
