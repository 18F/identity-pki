# vpc_module
This module performs the following:

- Creates a vpc when network_us_east_1 flag set to true. To leave out the legacy space and avoid polluting another block of private address space that could prevent future peering, the module is using ip address range 172.17.32.0/22 for us-east-1. It is recommended to use a similar non overlapping range from 172.16/12 prefix for other regions as well. While passing the primary CIDR to new VPC and if this vpc is intended to use for vpc peering please ensure the following, more info [here](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html): 

      - You cannot create a VPC peering connection between VPCs that have matching or overlapping IPv4 
      CIDR blocks.

      - You cannot create a VPC peering connection between VPCs that have matching or overlapping IPv6 
      CIDR blocks.

      - If you have multiple IPv4 CIDR blocks, you can't create a VPC peering connection if any of the 
      CIDR blocks overlap, even if you intend to use only the non-overlapping CIDR blocks or only IPv6 
      CIDR blocks.

- A secondary CIDR calculated from network_layout module can be passed when calling this module, that will associate a secondary cidr to the vpc.

- Module at the current setup is creating vpc resources for data-services and app subnets. Following resources are created:
      - Database/App Subnets with CIDR calculated from network_layout module can be passed when calling this module
      - Both subnets are using the default route table with similar routes present in us-west-2
      - Different Network Acls is associated with these subnets(not default) similar to us-west-2 infrastructure
      - A default null security group is created
      - Security group associated with migration, app, data-services, app-alb hosts are created
      - VPC flow log is created with destination as cloudwatch logs


## Usage
```

locals {
  network_layout  = module.network_layout.network_layout
}

module "network_layout" {
    source = "../identity-devops/terraform/modules/network_layout"
  }

module "network_us_east_1" {
  count = var.enable_us_east_1_vpc ? 1 : 0
  providers = {
    aws = aws.use1
  }
  
  source                    = "../modules/vpc_module"
  apps_enabled              = var.apps_enabled
  aws_services              = local.aws_endpoints
  az                        = local.network_layout["us-east-1"][var.env_type]._zones
  env_name                  = var.env_name
  env_type                  = var.env_type
  fisma_tag                 = var.fisma_tag
  flow_log_iam_role_arn     = module.application_iam_roles.flow_role_iam_role_arn
  github_ipv4_cidr_blocks   = local.github_ipv4
  nessusserver_ip           = var.nessusserver_ip
  nessus_public_access_mode = local.nessus_public_access_mode
  proxy_port                = var.proxy_port
  rds_db_port               = var.rds_db_port
  region                    = "us-east-1"
  secondary_cidr_block      = local.network_layout["us-east-1"][var.env_type]._network
  vpc_cidr_block            = var.us_east_1_vpc_cidr_block    
}

```