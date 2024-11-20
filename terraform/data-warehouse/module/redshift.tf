# Disabling Redshift Cluster Logging Disabled warning. KICS isn't aware of the new resource type.
# kics-scan disable=15ffbacc-fa42-4f6f-a57d-2feac7365caa

module "redshift_credentials" {
  source = "../../modules/secrets_manager_secret"

  exclude_punctuation        = true
  include_space              = false
  require_each_included_type = true
  secret_name                = "redshift/${var.env_name}-analytics-${var.redshift_username}"
  secret_string = jsonencode(
    {
      username = var.redshift_username
      # This module replaces the string with a random password and is a false positive.
      # kics-scan ignore-line
      password = "generateRandomPassword"
    }
  )
  recovery_window_in_days = 0
}

data "aws_secretsmanager_secret_version" "redshift_credentials" {
  secret_id  = module.redshift_credentials.secret_id
  depends_on = [module.redshift_credentials]
}

resource "aws_kms_key" "redshift_kms_key" {
  description             = "KMSKeyForRedshift"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.redshift_kms.json
}

resource "aws_kms_alias" "redshift_kms_key" {
  name          = "alias/${var.env_name}-kms-redshift"
  target_key_id = aws_kms_key.redshift_kms_key.key_id
}

resource "aws_redshift_parameter_group" "redshift_configuration" {
  name   = "${var.env_name}-analytics-redshift-configuration"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "use_fips_ssl"
    value = "true"
  }
}

resource "aws_redshift_cluster" "redshift" {
  cluster_identifier                  = "${var.env_name}-analytics"
  database_name                       = "analytics"
  master_username                     = jsondecode(data.aws_secretsmanager_secret_version.redshift_credentials.secret_string)["username"]
  master_password                     = jsondecode(data.aws_secretsmanager_secret_version.redshift_credentials.secret_string)["password"]
  node_type                           = var.redshift_node_type
  cluster_type                        = var.redshift_cluster_type
  number_of_nodes                     = var.redshift_number_of_nodes
  cluster_subnet_group_name           = aws_redshift_subnet_group.redshift_subnet_group.name
  publicly_accessible                 = false
  enhanced_vpc_routing                = true
  iam_roles                           = [aws_iam_role.redshift_role.arn]
  encrypted                           = true
  kms_key_id                          = aws_kms_key.redshift_kms_key.arn
  cluster_parameter_group_name        = aws_redshift_parameter_group.redshift_configuration.name
  vpc_security_group_ids              = [aws_security_group.redshift.id]
  skip_final_snapshot                 = true
  automated_snapshot_retention_period = 30

  depends_on = [
    module.redshift_credentials
  ]
}

resource "aws_redshift_logging" "redshift" {
  cluster_identifier   = aws_redshift_cluster.redshift.id
  log_destination_type = "cloudwatch"
  log_exports = [
    "connectionlog",
    "userlog",
    "useractivitylog"
  ]
  depends_on = [
    aws_cloudwatch_log_group.redshift_logs["connectionlog"],
    aws_cloudwatch_log_group.redshift_logs["useractivitylog"],
    aws_cloudwatch_log_group.redshift_logs["userlog"]
  ]
}

resource "aws_redshift_cluster" "dr_redshift" {
  count = var.dr_restore_redshift_dw && (var.dr_redshift_snapshot_identifier != "") ? 1 : 0

  snapshot_identifier = var.dr_redshift_snapshot_identifier

  cluster_identifier                  = "${var.env_name}-analytics-restored"
  database_name                       = "analytics"
  master_username                     = jsondecode(data.aws_secretsmanager_secret_version.redshift_credentials.secret_string)["username"]
  master_password                     = jsondecode(data.aws_secretsmanager_secret_version.redshift_credentials.secret_string)["password"]
  node_type                           = var.redshift_node_type
  cluster_type                        = var.redshift_cluster_type
  number_of_nodes                     = var.redshift_number_of_nodes
  cluster_subnet_group_name           = aws_redshift_subnet_group.redshift_subnet_group.name
  publicly_accessible                 = false
  enhanced_vpc_routing                = true
  iam_roles                           = [aws_iam_role.redshift_role.arn]
  encrypted                           = true
  kms_key_id                          = aws_kms_key.redshift_kms_key.arn
  cluster_parameter_group_name        = aws_redshift_parameter_group.redshift_configuration.name
  vpc_security_group_ids              = [aws_security_group.redshift.id]
  skip_final_snapshot                 = true
  automated_snapshot_retention_period = 30

  depends_on = [
    module.redshift_credentials
  ]
}

resource "aws_redshift_logging" "dr_redshift" {
  count                = var.dr_restore_redshift_dw && (var.dr_redshift_snapshot_identifier != "") ? 1 : 0
  cluster_identifier   = aws_redshift_cluster.dr_redshift[count.index].id
  log_destination_type = "cloudwatch"
  log_exports = [
    "connectionlog",
    "userlog",
    "useractivitylog"
  ]
  depends_on = [
    aws_cloudwatch_log_group.redshift_logs["connectionlog"],
    aws_cloudwatch_log_group.redshift_logs["useractivitylog"],
    aws_cloudwatch_log_group.redshift_logs["userlog"]
  ]
}
