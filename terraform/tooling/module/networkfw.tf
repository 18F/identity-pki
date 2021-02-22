# The networkfirewall is required because not all services that terraform needs
# to operate on can be a VPC endpoint, so we are locking this environment
# down using the networkfw.

resource "aws_networkfirewall_rule_group" "networkfw" {
  capacity    = 100
  description = "Permits TLS traffic to selected endpoints"
  name        = "networkfw"
  type        = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [
          ".amazonaws.com",
          "proxy.golang.org",
          "github.com"
        ]
      }
    }
  }

  tags = {
    Name = "permit TLS to selected endpoints"
  }
}

resource "aws_networkfirewall_firewall_policy" "networkfw" {
  name = "networkfw"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.networkfw.arn
    }
  }

  tags = {
    Name = "Network firewall rules for auto_terraform"
  }
}

resource "aws_networkfirewall_firewall" "networkfw" {
  name                = "networkfw"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.networkfw.arn
  vpc_id              = aws_vpc.auto_terraform.id
  subnet_mapping {
    subnet_id = aws_subnet.auto_terraform_fw.id
  }

  tags = {
    Name = "Network Firewall for autotf"
  }
}

resource "aws_subnet" "auto_terraform_fw" {
  vpc_id     = aws_vpc.auto_terraform.id
  cidr_block = "10.0.3.0/28"

  tags = {
    Name = "auto_terraform firewall"
  }
}

resource "aws_route_table" "auto_terraform_fw" {
  vpc_id = aws_vpc.auto_terraform.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.auto_terraform.id
  }

  tags = {
    Name = "auto_terraform fw"
  }
}

resource "aws_route_table_association" "auto_terraform_fw" {
  subnet_id = aws_subnet.auto_terraform_fw.id
  route_table_id = aws_route_table.auto_terraform_fw.id
}

data "aws_vpc_endpoint" "networkfw" {
  vpc_id       = aws_vpc.auto_terraform.id

  tags = {
    "AWSNetworkFirewallManaged" = "true"
    "Firewall" = aws_networkfirewall_firewall.networkfw.arn
  }

  depends_on = [aws_networkfirewall_firewall.networkfw]
}

resource "aws_networkfirewall_logging_configuration" "networkfw" {
  firewall_arn = aws_networkfirewall_firewall.networkfw.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = "auto-terraform"
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
    log_destination_config {
      log_destination = {
        logGroup = "auto-terraform"
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}
