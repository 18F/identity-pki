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

### remove once moving is complete

moved {
  from = module.base_security_uw2.aws_security_group.base
  to   = module.network_uw2.aws_security_group.base
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["kms"]
  to   = module.network_uw2.aws_security_group.endpoint["kms"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["ssm"]
  to   = module.network_uw2.aws_security_group.endpoint["ssm"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["ssmmessages"]
  to   = module.network_uw2.aws_security_group.endpoint["ssmmessages"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["ec2"]
  to   = module.network_uw2.aws_security_group.endpoint["ec2"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["ec2messages"]
  to   = module.network_uw2.aws_security_group.endpoint["ec2messages"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["logs"]
  to   = module.network_uw2.aws_security_group.endpoint["logs"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["monitoring"]
  to   = module.network_uw2.aws_security_group.endpoint["monitoring"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["secretsmanager"]
  to   = module.network_uw2.aws_security_group.endpoint["secretsmanager"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["sts"]
  to   = module.network_uw2.aws_security_group.endpoint["sts"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["events"]
  to   = module.network_uw2.aws_security_group.endpoint["events"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["sns"]
  to   = module.network_uw2.aws_security_group.endpoint["sns"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["lambda"]
  to   = module.network_uw2.aws_security_group.endpoint["lambda"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["sqs"]
  to   = module.network_uw2.aws_security_group.endpoint["sqs"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["kms"]
  to   = module.network_uw2.aws_vpc_endpoint.service["kms"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["ssm"]
  to   = module.network_uw2.aws_vpc_endpoint.service["ssm"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["ssmmessages"]
  to   = module.network_uw2.aws_vpc_endpoint.service["ssmmessages"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["ec2"]
  to   = module.network_uw2.aws_vpc_endpoint.service["ec2"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["ec2messages"]
  to   = module.network_uw2.aws_vpc_endpoint.service["ec2messages"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["logs"]
  to   = module.network_uw2.aws_vpc_endpoint.service["logs"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["monitoring"]
  to   = module.network_uw2.aws_vpc_endpoint.service["monitoring"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["secretsmanager"]
  to   = module.network_uw2.aws_vpc_endpoint.service["secretsmanager"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["sts"]
  to   = module.network_uw2.aws_vpc_endpoint.service["sts"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["events"]
  to   = module.network_uw2.aws_vpc_endpoint.service["events"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["sns"]
  to   = module.network_uw2.aws_vpc_endpoint.service["sns"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["lambda"]
  to   = module.network_uw2.aws_vpc_endpoint.service["lambda"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["sqs"]
  to   = module.network_uw2.aws_vpc_endpoint.service["sqs"]
}

moved {
  from = module.base_security_uw2.aws_vpc_endpoint.service["dms"]
  to   = module.network_uw2.aws_vpc_endpoint.service["dms"]
}

moved {
  from = module.base_security_uw2.aws_security_group.endpoint["dms"]
  to   = module.network_uw2.aws_security_group.endpoint["dms"]
}
