resource "aws_security_group" "nessus_main" {
  description = "Main Security Group for Nessus Server"
  name        = "nessus_server_main"

  # needed for ssm
  egress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # needed for apt-get
  egress {
    description = "Allow apt-get to work"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDS scan access
  egress {
    description = "Allow RDS DB scans"
    from_port   = var.rds_db_port
    to_port     = var.rds_db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "nessus_server_main"
    CreateDate = data.aws_ip_ranges.ec2.create_date
    SyncToken  = data.aws_ip_ranges.ec2.sync_token
  }
}

resource "aws_security_group" "nessus_ipv4" {
  for_each    = local.chunked_ipv4
  description = "EC2 IPv4 ingress for Nessus Server, group ${each.key}"
  name        = "nessus_server_ipv4_${each.key}"

  ingress {
    from_port   = "8834"
    to_port     = "8834"
    protocol    = "tcp"
    cidr_blocks = each.value
  }

  tags = {
    Name       = "nessus_server_ipv4_${each.key}"
    CreateDate = data.aws_ip_ranges.ec2.create_date
    SyncToken  = data.aws_ip_ranges.ec2.sync_token
  }
}

resource "aws_security_group" "nessus_ipv6" {
  for_each    = local.chunked_ipv6
  description = "EC2 IPv6 ingress for Nessus Server, group ${each.key}"
  name        = "nessus_server_ipv6_${each.key}"

  ingress {
    from_port        = "8834"
    to_port          = "8834"
    protocol         = "tcp"
    ipv6_cidr_blocks = each.value
  }

  tags = {
    Name       = "nessus_server_ipv6_${each.key}"
    CreateDate = data.aws_ip_ranges.ec2.create_date
    SyncToken  = data.aws_ip_ranges.ec2.sync_token
  }
}
