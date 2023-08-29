module "application_iam_roles" {
  source                         = "../modules/application_iam_roles"
  env_name                       = "reviewapp" # Has to be alphanumeric, otherwise a couple bucket Sid's will fail because of the name containing a _
  region                         = var.region
  apps_enabled                   = 1
  identity_sms_aws_account_id    = "035466892286"
  escrow_bucket_arn              = "arn:aws:s3:::login-gov-escrow-dev.894947205914-us-west-2"
  escrow_bucket_id               = "login-gov-escrow-dev.894947205914-us-west-2"
  cloudfront_oai_iam_arn         = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E2GMERCRI9EAR7"
  idp_doc_capture_arn            = "arn:aws:s3:::login-gov-idp-doc-capture-dev.894947205914-us-west-2"
  idp_doc_capture_kms_arn        = "arn:aws:kms:us-west-2:894947205914:key/d299e045-f0ca-4e37-81eb-ce037c67fa5e"
  kinesis_bucket_arn             = "arn:aws:s3:::login-gov-athena-queries-dev.894947205914-us-west-2"
  kinesis_kms_key_arn            = "arn:aws:kms:us-west-2:894947205914:key/77e31a6f-8464-4bad-9c7f-b7247844e66a"
  slack_events_sns_hook_arn      = "arn:aws:sns:us-west-2:894947205914:slack-hook-otherevents"
  slack_events_sns_hook_arn_use1 = "arn:aws:sns:us-east-1:894947205914:slack-hook-otherevents"
  root_domain                    = var.dnszone
  gitlab_enabled                 = false
  pivcac_route53_zone_id         = aws_route53_zone.pivcac.zone_id
  ssm_policy                     = "" # Not setting so policies aren't created
  ssm_access_enabled             = false
  ipv4_secondary_cidr            = local.vpc_cidr # No secondary cidr at the moment, pointing to primary cidr
  eks_oidc_provider_arn          = module.review_app.eks_oidc_provider_arn
  eks_oidc_provider              = module.review_app.oidc_provider
  service_accounts               = ["review-apps:*pivcac*", "review-apps:*app*", "review-apps:*idp*", "review-apps:*worker*"]
}
