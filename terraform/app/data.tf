data "aws_kms_key" "rds_alias" {
  key_id = "alias/aws/rds"
}
