data "aws_secretsmanager_random_password" "password" {
  exclude_characters         = var.exclude_characters
  exclude_lowercase          = var.exclude_lowercase
  exclude_numbers            = var.exclude_numbers
  exclude_punctuation        = var.exclude_punctuation
  exclude_uppercase          = var.exclude_uppercase
  include_space              = var.include_space
  password_length            = var.password_length
  require_each_included_type = var.require_each_included_type
}

resource "aws_secretsmanager_secret" "secret" {
  name                    = var.secret_name
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id
  tags                    = var.secret_tags

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      kms_key_id = replica.value.kms_replica_key_id
      region     = replica.value.region
    }
  }
}

resource "aws_secretsmanager_secret_version" "secret" {
  count         = length(var.secret_string) > 0 ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = replace(var.secret_string, "generateRandomPassword", data.aws_secretsmanager_random_password.password.random_password)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
