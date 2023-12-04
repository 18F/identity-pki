locals {
  retention_days = (var.env_name == "prod" || var.env_name == "staging" ? "3653" : "30")
}

resource "aws_cloudwatch_log_group" "imagebuild_base" {
  name              = "/aws/codebuild/${var.name}-${data.aws_region.current.name}-${var.env_name}-imagebuild-base"
  retention_in_days = local.retention_days

  tags = {
    environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "imagebuild_rails" {
  name              = "/aws/codebuild/${var.name}-${data.aws_region.current.name}-${var.env_name}-imagebuild-rails"
  retention_in_days = local.retention_days

  tags = {
    environment = var.env_name
  }
}