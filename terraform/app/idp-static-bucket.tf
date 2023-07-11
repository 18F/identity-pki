module "idp_static_bucket_uw2" {
  count  = var.enable_idp_static_bucket ? 1 : 0
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
  from = aws_s3_bucket.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket.idp_static_bucket
}

moved {
  from = aws_s3_bucket_cors_configuration.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_cors_configuration.idp_static_bucket
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_lifecycle_configuration.idp_static_bucket
}

moved {
  from = aws_s3_bucket_logging.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_logging.idp_static_bucket
}

moved {
  from = aws_s3_bucket_ownership_controls.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_ownership_controls.idp_static_bucket
}

moved {
  from = aws_s3_bucket_policy.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_policy.idp_static_bucket
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_server_side_encryption_configuration.idp_static_bucket
}

moved {
  from = aws_s3_bucket_versioning.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_versioning.idp_static_bucket
}

moved {
  from = aws_s3_bucket_website_configuration.idp_static_bucket[0]
  to   = module.idp_static_bucket_uw2[0].aws_s3_bucket_website_configuration.idp_static_bucket
}

moved {
  from = aws_s3_object.cloudfront_custom_pages["5xx-codes/503.html"]
  to   = module.idp_static_bucket_uw2[0].aws_s3_object.cloudfront_custom_pages["5xx-codes/503.html"]
}

moved {
  from = aws_s3_object.cloudfront_custom_pages["maintenance/maintenance.html"]
  to   = module.idp_static_bucket_uw2[0].aws_s3_object.cloudfront_custom_pages["maintenance/maintenance.html"]
}

moved {
  from = module.idp_static_bucket_config[0]
  to   = module.idp_static_bucket_uw2[0].module.idp_static_bucket_config
}
