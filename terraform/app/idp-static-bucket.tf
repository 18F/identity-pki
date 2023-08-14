module "idp_static_bucket_uw2" {
  source = "../modules/idp_static_bucket"

  env_name                               = var.env_name
  region                                 = var.region
  force_destroy_idp_static_bucket        = var.force_destroy_idp_static_bucket
  root_domain                            = var.root_domain
  idp_static_bucket_cross_account_access = var.idp_static_bucket_cross_account_access
  cloudfront_custom_pages                = var.cloudfront_custom_pages
  idp_iam_role_arn                       = module.application_iam_roles.idp_iam_role_arn
  migration_iam_role_arn                 = module.application_iam_roles.migration_iam_role_arn
  cloudfront_oai_iam_arn                 = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
}

##### moved blocks, remove once state moves are complete

moved {
  from = module.idp_static_bucket_uw2[0]
  to   = module.idp_static_bucket_uw2
}

module "idp_static_bucket_use1" {
  count  = var.enable_us_east_1_infra ? 1 : 0
  source = "../modules/idp_static_bucket"
  providers = {
    aws = aws.use1
  }

  env_name                               = var.env_name
  region                                 = "us-east-1"
  force_destroy_idp_static_bucket        = var.force_destroy_idp_static_bucket
  root_domain                            = var.root_domain
  idp_static_bucket_cross_account_access = var.idp_static_bucket_cross_account_access
  cloudfront_custom_pages                = var.cloudfront_custom_pages
  idp_iam_role_arn                       = module.application_iam_roles.idp_iam_role_arn
  migration_iam_role_arn                 = module.application_iam_roles.migration_iam_role_arn
  cloudfront_oai_iam_arn                 = aws_cloudfront_origin_access_identity.cloudfront_oai.iam_arn
}