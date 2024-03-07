module "app_static_bucket_uw2" {
  source = "../modules/app_static_bucket"

  count                                  = var.apps_enabled
  env_name                               = var.env_name
  region                                 = var.region
  force_destroy_app_static_bucket        = var.force_destroy_app_static_bucket
  root_domain                            = var.root_domain
  app_static_bucket_cross_account_access = var.app_static_bucket_cross_account_access
  cloudfront_custom_pages                = var.cloudfront_custom_pages
  app_iam_role_arn                       = module.application_iam_roles.app_iam_role_arn
  cloudfront_oai_iam_arn                 = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
}

module "app_static_bucket_use1" {
  source = "../modules/app_static_bucket"
  providers = {
    aws = aws.use1
  }

  count                                  = var.enable_us_east_1_infra && var.apps_enabled == 1 ? 1 : 0
  env_name                               = var.env_name
  region                                 = "us-east-1"
  force_destroy_app_static_bucket        = var.force_destroy_app_static_bucket
  root_domain                            = var.root_domain
  app_static_bucket_cross_account_access = var.app_static_bucket_cross_account_access
  cloudfront_custom_pages                = var.cloudfront_custom_pages
  app_iam_role_arn                       = module.application_iam_roles.app_iam_role_arn
  cloudfront_oai_iam_arn                 = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
}