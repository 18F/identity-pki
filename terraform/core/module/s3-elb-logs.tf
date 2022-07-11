# Create a common bucket for storing ELB/ALB access logs
# The bucket name will be like this:
#   login-gov.elb-logs.<ACCOUNT_ID>-<AWS_REGION>
module "elb-logs" {
  # can't use variable for ref -- see https://github.com/hashicorp/terraform/issues/17994
  source = "github.com/18F/identity-terraform//elb_access_logs_bucket?ref=105ed397c16ebff2d97c762502ff73dcbda36ab9"

  region                     = var.region
  bucket_name_prefix         = local.bucket_name_prefix
  use_prefix_for_permissions = false
  inventory_bucket_arn       = local.inventory_bucket_uw2_arn
  lifecycle_days_standard_ia = 60   # 2 months
  lifecycle_days_glacier     = 365  # 1 year
  lifecycle_days_expire      = 2190 # 6 years
}

output "elb_log_bucket" {
  value = module.elb-logs.bucket_name
}
