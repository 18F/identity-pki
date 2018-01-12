variable "app_sg_ssh_cidr_blocks" { type="list" }
variable "ci_sg_ssh_cidr_blocks"  {
    type="list"
    default = ["127.0.0.1/32"] # hack to allow an empty list, which terraform can't handle
    description = "List of CIDR blocks to allow into all NACLs/SGs.  Only use in the CI VPC."
}
variable "power_users" { type="list" }
variable "amazon_netblocks" { type="list" }
variable "admin_subnet_cidr_block" { default = "172.16.33.16/28"} # 172.16.33.16 - 172.16.33.31
variable "app1_subnet_cidr_block"  { default = "172.16.33.96/28" } # 172.16.33.96 - 172.16.33.111
variable "spare_subnet_cidr_block"  { default = "172.16.33.112/28" } # 172.16.33.112 - 172.16.33.115
variable "db1_subnet_cidr_block"  { default = "172.16.33.32/28" } # 172.16.33.32 - 172.16.33.47
variable "db2_subnet_cidr_block"  { default = "172.16.33.48/28"} # 172.16.33.48 - 172.16.33.63
variable "db3_subnet_cidr_block"  { default = "172.16.33.64/28"} # 172.16.33.64 - 172.16.33.79
variable "chef_subnet_cidr_block"  { default = "172.16.33.80/28"} # 172.16.33.80 - 172.16.33.96
variable "idp1_subnet_cidr_block"  { default = "172.16.33.128/27" } # 172.16.33.128 - 172.16.33.159
variable "idp2_subnet_cidr_block"  { default = "172.16.33.160/27" } # 172.16.33.160 - 172.16.33.191
variable "idp3_subnet_cidr_block"  { default = "172.16.33.192/27" } # 172.16.33.192 - 172.16.33.223
variable "alb1_subnet_cidr_block"  { default = "172.16.33.224/28" } # 172.16.33.224 - 172.16.33.239
variable "alb2_subnet_cidr_block"  { default = "172.16.33.240/28" } # 172.16.33.240 - 172.16.33.255
variable "jumphost_subnet_cidr_block" { default = "172.16.33.0/28"} # 172.16.33.1 - 172.16.33.15
variable "obproxy1_subnet_cidr_block" { default = "172.16.32.0/28"} # 172.16.32.1 - 172.16.32.15
variable "obproxy2_subnet_cidr_block" { default = "172.16.32.16/28"} # 172.16.32.17 - 172.16.32.31
variable "vpc_cidr_block"         { default = "172.16.32.0/22" } # 172.16.32.0 - 172.16.35.255
#variable "vpc_cidr_block"         { default = "172.16.33.0/24" } # 172.16.32.0 - 172.16.35.255

variable "redshift_sg_id" {
  type = "map"
  default = {
    dev = "sg-6a8d8710"
    qa = "sg-0a584d70"
    int = "sg-aef2a8d4"
    dm = "sg-4c156f36"
    staging = "sg-cf5416b5"
    prod = "sg-12807b6f"
  }
}

variable "redshift_cidr_block" {
  type = "map"
  default = {
    dev = "34.214.42.173/32"
    qa = "35.160.215.243/32"
    int = "34.211.57.255/32"
    dm = "54.148.147.138/32"
    staging = "35.162.154.172/32"
    prod = "34.214.226.68/32"
  }
}
# CIDR block that is carved up for both the ASG elasticsearch instances and the
# elasticsearch ELBs.
# Range: 172.16.32.128 -> 172.16.32.191
variable "elasticsearch_cidr_block" { default = "172.16.34.128/26" }

# CIDR block that is carved up for both the ASG elk instances and the elk ELBs.
# Range: 172.16.34.192 -> 172.16.34.255
variable "elk_cidr_block" { default = "172.16.34.192/26" }

variable "ami_id" {}
variable "default_ami_id" {}
variable "jenkins_ami_id" {}
variable "chef_ami_id" {}
variable "chef_home" {}
variable "jumphost_ami_id" {}
variable "idp1_ami_id" {}
variable "idp2_ami_id" {}
variable "worker_ami_id" {}
variable "elasticsearch_ami_id" {}
variable "elk_ami_id" {}
variable "route53_id" {}
variable "apps_enabled" { default = 0 }

variable "elasticache_redis_node_type" {
    description = "Instance type used for redis elasticache. Changes incur downtime."
    default = "cache.t2.micro"
}

# prod/test environment flags
variable "basic_auth_enabled" {
    description = "Whether HTTP basic auth is enabled (controls ELB expected HTTP status code"
}
variable "asg_prevent_auto_terminate" {
    description = "Whether to protect auto scaled instances from automatic termination"
}
variable "enable_deletion_protection" {
    description = "Whether to protect against API deletion of certain resources"
}

variable "asg_enabled_metrics" {
    type = "list"
    description = "A list of cloudwatch metrics to collect on ASGs https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html#enabled_metrics"
    default = []
}

# https://downloads.chef.io/chef/stable/12.15.19#ubuntu
variable "chef_version" { default = "12.15.19" }
variable "chef_download_url" {
    default = "https://packages.chef.io/files/stable/chef/12.15.19/ubuntu/16.04/chef_12.15.19-1_amd64.deb"
}
variable "chef_download_sha256" {
    default = "7073541beb4294c994d4035a49afcf06ab45b3b3933b98a65b8059b7591df6b8"
}

variable "chef_url" { default = "https://chef.login.gov.internal/organizations/login-dev" }
variable "chef_databag_key_path" {}
variable "chef_id" {}
variable "chef_info" {}
variable "chef_id_key_path" {}
variable "chef_repo_gitref" { default = "master" }
variable "client" {}
variable "env_name" { }
variable "esnodes" { default = 2 }
variable "git_deploy_key_path" {}
variable "idp_node_count" { default = 1 }
variable "idp_worker_count" { default = 2 }
variable "instance_type_app" { default = "t2.medium" }
variable "instance_type_chef" { default = "t2.medium" }
variable "instance_type_elk" { default = "t2.medium" }
variable "instance_type_es" { default = "t2.medium" }
variable "instance_type_idp" { default = "t2.medium" }
variable "instance_type_jenkins" { default = "t2.medium" }
variable "instance_type_jumphost" { default = "t2.small" }
variable "instance_type_worker" { default = "t2.small" } # TODO way too small
variable "key_name" {}
variable "live_certs" {}
variable "name" { default = "login" }
variable "region" { default = "us-west-2" }
variable "availability_zones" { default = ["us-west-2a","us-west-2b","us-west-2c"] }
variable "outboundproxy_node_count" { default = "1" }
variable "outboundproxy1_ami_id" {}
variable "outboundproxy2_ami_id" {}
variable "version_info_bucket" {}
variable "version_info_region" {}

variable "root_domain" {
    description = "DNS domain to use as the root domain, e.g. login.gov"
}

# Auto scaling flags
variable "asg_auto_6h_recycle" {
    default = 0
    description = "Whether to automatically recycle IdP/worker/app servers every 6 hours"
}

# Auto scaling group desired counts
variable "asg_jumphost_desired" { default = 0 }
variable "asg_idp_min" { default = 0 }
variable "asg_idp_desired" { default = 0 }
variable "asg_idp_max" { default = 8 }
variable "asg_worker_min" { default = 0 }
variable "asg_worker_desired" { default = 0 }
variable "asg_worker_max" { default = 8 }
variable "asg_elasticsearch_desired" { default = 0 }
variable "asg_elk_desired" { default = 0 }
variable "asg_app_min" { default = 0 }
variable "asg_app_desired" { default = 0 }
variable "asg_app_max" { default = 8 }

variable "idp_web_acl_id" {
    default = "eb5d2b12-a361-4fa0-88f2-8f632f6a9819"
    description = "WAF Web ACL ID to attach to this environment's ALBs (shouldn't need to be changed). Only used when enable_waf=true."
    # Get this from https://console.aws.amazon.com/waf/home?region=us-west-2#/webacls
    # or `aws waf-regional list-web-acls`
}
variable "enable_waf" {
    default = false
    description = "Enable WAF to filter ingress traffic."
    # See ../../doc/technical/waf.md
}

# Several variables used by the terraform-modules/bootstrap/ module for running
# provision.sh to clone git repos and run chef.
variable "bootstrap_main_git_ref" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out"
}
variable "bootstrap_main_s3_ssh_key_url" {
    # TODO use terraform locals to compute this once we upgrade to 0.10.*
    description = "S3 path to find an SSH key for cloning identity-devops"
}
variable "bootstrap_main_git_clone_url" {
    default = "git@github.com:18F/identity-devops"
    description = "URL for provision.sh to use to clone identity-devops"
}
variable "bootstrap_private_git_ref" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out"
}
variable "bootstrap_private_s3_ssh_key_url" {
    description = "S3 path to find an SSH key for cloning identity-devops-private"
}
variable "bootstrap_private_git_clone_url" {
    default = "git@github.com:18F/identity-devops-private"
    description = "URL for provision.sh to use to clone identity-devops-private"
}

# These variables are used both to create the continuous integration VPC (a
# VPC with only base services like the Postgres and Redis, so that nodes can be
# integration tested), and to help with migration one node at a time to
# autoscaled nodes that do not need a chef server to bootstrap.
#
# NOTE: These must be numbers, as terraform does not support boolean values,
# only numbers and strings.
#
# See: https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

variable "non_asg_jumphost_enabled" {
    default = 1
    description = "Enable non autoscaled jumphost node"
}

variable "non_asg_jenkins_enabled" {
    default = 1
    description = "Enable non autoscaled jenkins node"
}

variable "non_asg_es_enabled" {
    default = 1
    description = "Enable non autoscaled elasticsearch nodes"
}

variable "non_asg_elk_enabled" {
    default = 1
    description = "Enable non autoscaled elk node"
}

variable "chef_server_enabled" {
    default = 1
    description = "Enable Chef Server node"
}

variable "alb_enabled" {
    default = 1
    description = "Enable ALB for idp hosts"
}

# This variable is needed for service discovery

variable "certificates_bucket_name_prefix" {
    description = "Base name for the self signed certificates bucket used for service discovery"
    default = "login-gov-internal-certs-test"
}

# This is needed so the application can download its secrets

variable "app_secrets_bucket_name_prefix" {
    description = "Base name for the bucket that contains application secrets"
    default = "login-gov-app-secrets"
}

# This variable is used to allow access to 80/443 on the general internet
# Set it to [] to turn access off, "0.0.0.0/0" to allow it.
variable "outbound_subnets" {
  default = ["0.0.0.0/0"]
  type="list"
}

variable "outboundproxy_ami_id" {}
variable "instance_type_outboundproxy" { default = "t2.small" }
variable "asg_outboundproxy_desired" { default = 0 }

# Per instance git refs, useful for testing different branches in the same
# environment on different nodes.
variable "bootstrap_main_git_ref_elasticsearch" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out for elasticsearch"
}
variable "bootstrap_private_git_ref_elasticsearch" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out for elasticsearch"
}
variable "bootstrap_main_git_ref_elk" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out for elk"
}
variable "bootstrap_private_git_ref_elk" {
    default = "HEAD"
    description = "Git ref in identity-devops for provision.sh to check out for elk"
}
