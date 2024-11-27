module "idp_secrets" {
  source = "../modules/secrets_manager_secret"

  for_each = var.idp_secrets_manager_secrets_enabled ? var.idp_secrets_manager_secrets : {}

  secret_name   = "${var.env_name}/idp/${each.value.name}"
  secret_string = ""
  secret_tags   = each.value.tags
  kms_key_id    = aws_kms_alias.idp_secrets_manager_kms_key_alias[0].name

  replica_regions = var.enable_us_east_1_infra ? [{
    region             = "us-east-1"
    kms_replica_key_id = aws_kms_alias.idp_secrets_manager_kms_replica_key_alias[0].name
  }] : []
}

resource "aws_kms_key" "idp_secrets_manager_kms_key" {
  count               = var.idp_secrets_manager_secrets_enabled ? 1 : 0
  provider            = aws.usw2
  description         = "KMS Key for IDP Secrets Manager secrets"
  multi_region        = true
  enable_key_rotation = true
}

resource "aws_kms_alias" "idp_secrets_manager_kms_key_alias" {
  count         = var.idp_secrets_manager_secrets_enabled ? 1 : 0
  name          = "alias/${var.env_name}-idp-secrets-manager"
  target_key_id = aws_kms_key.idp_secrets_manager_kms_key[0].key_id
}

resource "aws_kms_replica_key" "idp_secrets_manager_kms_replica_key" {
  count    = (var.enable_us_east_1_infra && var.idp_secrets_manager_secrets_enabled) ? 1 : 0
  provider = aws.use1

  primary_key_arn = aws_kms_key.idp_secrets_manager_kms_key[0].arn
}

resource "aws_kms_alias" "idp_secrets_manager_kms_replica_key_alias" {
  count    = (var.enable_us_east_1_infra && var.idp_secrets_manager_secrets_enabled) ? 1 : 0
  provider = aws.use1

  name          = "alias/${var.env_name}-idp-secrets-manager-replica"
  target_key_id = aws_kms_replica_key.idp_secrets_manager_kms_replica_key[0].arn
}
