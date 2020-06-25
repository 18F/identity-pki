variable "env_name" {
  description = "Name of the environment Analytics is accessing."
  default     = ""
}

#variable "redshift_master_password" {}

variable "analytics_version" {}

variable "redshift_node_type" {
  description = "Type of nodes in the Redshift cluster."
  default     = "dc2.large"
}

variable "redshift_cluster_type" {
  description = "Type of Redshift cluster."
  default     = "single-node"
}

variable "redshift_number_of_nodes" {
  description = "Number of nodes in the Redshift cluster."
  default     = 1
}

variable "jumphost_cidr_block" {
  type    = map(string)
  default = {
    staging = "34.216.215.0/26"
    prod    = "34.216.215.64/26"
  }
}

variable "vpc_cidr_block" {
  default = "10.1.0.0/16"
}

variable "region" {
  default = "us-west-2"
}

variable "lambda_kms_key_id" {
  default = "b10a84ce-1f80-44bc-8d0f-7a547b45ce53"
}

variable "wlm_json_configuration" {
  default = "[{\"query_concurrency\": 50}]"
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table to use for state locking with the S3 state backend, e.g. 'terraform-locks'"
  default     = "terraform_locks"
}

variable "manage_state_bucket" {
  description = <<EOM
Whether to manage the TF remote state bucket and lock table.
Set this to false if you want to skip this for bootstrapping.
EOM
  type        = bool
  default     = true
}
