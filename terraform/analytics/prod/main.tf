provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["461353137281"] # require analytics
  profile             = "analytics"
}

# Stub remote config
terraform {
  backend "s3" {
  }
}

module "main" {
  source = "../module"

  env_name                 = "prod"
  #redshift_master_password = var.redshift_master_password
  redshift_node_type       = "dc2.8xlarge"
  redshift_cluster_type    = "multi-node"
  redshift_number_of_nodes = 4
  analytics_version        = "account_migration_v16"
  lambda_memory_size     = 512
  lambda_hot_memory_size = 3008
  lambda_hot_timeout     = 900
}
