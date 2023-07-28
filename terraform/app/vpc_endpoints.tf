locals {
  aws_endpoints = {
    "dms"            = { vpc_cidr_egress = true },
    "kms"            = { vpc_cidr_egress = true },
    "logs"           = { vpc_cidr_egress = true },
    "monitoring"     = { vpc_cidr_egress = true },
    "ssm"            = { vpc_cidr_egress = true },
    "ssmmessages"    = { vpc_cidr_egress = true },
    "ec2"            = { vpc_cidr_egress = true },
    "ec2messages"    = { vpc_cidr_egress = true },
    "secretsmanager" = { vpc_cidr_egress = true },
    "sns"            = { vpc_cidr_egress = true },
    "lambda"         = { vpc_cidr_egress = false },
    "sqs"            = { vpc_cidr_egress = true },
    "sts"            = { vpc_cidr_egress = true },
    "events"         = { vpc_cidr_egress = true },
  }
}

module "base_security_uw2" {
  source = "../modules/base_security"

  name                   = var.name
  env_name               = var.env_name
  region                 = var.region
  fisma_tag              = var.fisma_tag
  vpc_id                 = aws_vpc.default.id
  proxy_port             = var.proxy_port
  obproxy_security_group = module.outboundproxy_net_uw2.security_group_id
  vpc_cidr_block         = aws_vpc_ipv4_cidr_block_association.secondary_cidr.cidr_block
  s3_prefix_list_id      = aws_vpc_endpoint.private-s3.prefix_list_id
  aws_services           = local.aws_endpoints
  app_subnets            = aws_subnet.app
}

### remove once moving is complete

moved {
  from = aws_security_group.base
  to   = module.base_security_uw2.aws_security_group.base
}

moved {
  from = aws_security_group.kms_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["kms"]
}

moved {
  from = aws_security_group.ssm_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["ssm"]
}

moved {
  from = aws_security_group.ssmmessages_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["ssmmessages"]
}

moved {
  from = aws_security_group.ec2_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["ec2"]
}

moved {
  from = aws_security_group.ec2messages_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["ec2messages"]
}

moved {
  from = aws_security_group.logs_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["logs"]
}

moved {
  from = aws_security_group.monitoring_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["monitoring"]
}

moved {
  from = aws_security_group.secretsmanager_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["secretsmanager"]
}

moved {
  from = aws_security_group.sts_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["sts"]
}

moved {
  from = aws_security_group.events_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["events"]
}

moved {
  from = aws_security_group.sns_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["sns"]
}

moved {
  from = aws_security_group.lambda_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["lambda"]
}

moved {
  from = aws_security_group.sqs_endpoint
  to   = module.base_security_uw2.aws_security_group.endpoint["sqs"]
}

moved {
  from = aws_vpc_endpoint.kms
  to   = module.base_security_uw2.aws_vpc_endpoint.service["kms"]
}

moved {
  from = aws_vpc_endpoint.ssm
  to   = module.base_security_uw2.aws_vpc_endpoint.service["ssm"]
}

moved {
  from = aws_vpc_endpoint.ssmmessages
  to   = module.base_security_uw2.aws_vpc_endpoint.service["ssmmessages"]
}

moved {
  from = aws_vpc_endpoint.ec2
  to   = module.base_security_uw2.aws_vpc_endpoint.service["ec2"]
}

moved {
  from = aws_vpc_endpoint.ec2messages
  to   = module.base_security_uw2.aws_vpc_endpoint.service["ec2messages"]
}

moved {
  from = aws_vpc_endpoint.logs
  to   = module.base_security_uw2.aws_vpc_endpoint.service["logs"]
}

moved {
  from = aws_vpc_endpoint.monitoring
  to   = module.base_security_uw2.aws_vpc_endpoint.service["monitoring"]
}

moved {
  from = aws_vpc_endpoint.secretsmanager
  to   = module.base_security_uw2.aws_vpc_endpoint.service["secretsmanager"]
}

moved {
  from = aws_vpc_endpoint.sts
  to   = module.base_security_uw2.aws_vpc_endpoint.service["sts"]
}

moved {
  from = aws_vpc_endpoint.events
  to   = module.base_security_uw2.aws_vpc_endpoint.service["events"]
}

moved {
  from = aws_vpc_endpoint.sns
  to   = module.base_security_uw2.aws_vpc_endpoint.service["sns"]
}

moved {
  from = aws_vpc_endpoint.lambda
  to   = module.base_security_uw2.aws_vpc_endpoint.service["lambda"]
}

moved {
  from = aws_vpc_endpoint.sqs
  to   = module.base_security_uw2.aws_vpc_endpoint.service["sqs"]
}
