# Create a common bucket for storing ELB/ALB access logs
# The bucket name will be like this:
#   login-gov.elb-logs.<ACCOUNT_ID>-<AWS_REGION>
module "elb_logs" {
  source = "github.com/18F/identity-terraform//elb_access_logs_bucket?ref=06abe06fd3208a57261358d431ee731f828574f2"
  #source = "../../../../identity-terraform/elb_access_logs_bucket"

  region                     = var.region
  bucket_name_prefix         = local.bucket_name_prefix
  use_prefix_for_permissions = false
  inventory_bucket_arn       = local.inventory_bucket_uw2_arn
  logging_bucket_id          = data.aws_s3_bucket.s3_logs_bucket_uw2.id
  lifecycle_days_standard_ia = 60   # 2 months
  lifecycle_days_glacier     = 365  # 1 year
  lifecycle_days_expire      = 2190 # 6 years
}

moved {
  from = module.elb-logs
  to   = module.elb_logs
}

