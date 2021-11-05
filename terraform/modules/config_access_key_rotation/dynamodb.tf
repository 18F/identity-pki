resource "aws_dynamodb_table" "config_access_key_rotation_dynamodb_table" {
  name         = "${var.config_access_key_rotation_name}-dynamodb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"

  attribute {
    name = "uuid"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  tags = {
    Name = "${var.config_access_key_rotation_name}-dynamodb"
  }
}