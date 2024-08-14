output "app_secrets_bucket_ue1" {
  value = module.app_secrets_bucket_ue1.bucket_name
}

output "app_secrets_bucket_uw2" {
  value = module.app_secrets_bucket_uw2.bucket_name
}

output "elb_log_bucket" {
  value = module.elb_logs.bucket_name
}
