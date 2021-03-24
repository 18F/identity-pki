locals {
  yaml_data = yamldecode(file("validdomain.yaml"))
}


#################################################################
################# Network Implementation  #######################
#################################################################

resource "aws_subnet" "nat" {
  for_each          = toset(var.az_zones)
  availability_zone = each.key
  cidr_block        = var.nat_cidr_blocks[each.key]
  vpc_id            = aws_vpc.default.id
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}-NAT-Subnet-${each.key}"
  }
}

resource "aws_nat_gateway" "gw" {
  for_each      = toset(var.az_zones)  
  allocation_id = var.eip_allocation_blocks[each.key]
  subnet_id     = aws_subnet.nat[each.key].id
  tags = {
    Name = "${var.name}-NAT-Gateway-${each.key}"
  }
}

resource "aws_subnet" "firewall" {
  for_each          = toset(var.az_zones)
  availability_zone = each.key
  cidr_block        = var.firewall_cidr_blocks[each.key]
  vpc_id            = aws_vpc.default.id
  tags = {
    Name = "${var.name}-Firewall-Subnet-${each.key}"
  }
}

resource "aws_networkfirewall_firewall_policy" "fwpolicy" {
  for_each          = toset(var.az_zones)
  name              = "fw-policy-${each.key}"
  firewall_policy {
    stateless_default_actions = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.fqdn_allow.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.fqdn_deny.arn
    }
  }
}


resource "aws_networkfirewall_firewall" "firewall" {
  for_each            = toset(var.az_zones)
  firewall_policy_arn = aws_networkfirewall_firewall_policy.fwpolicy[each.key].arn
  name                = "${var.env_name}-Firewall-${each.key}"
  vpc_id              = aws_vpc.default.id
  subnet_mapping {
    subnet_id          = aws_subnet.firewall[each.key].id
  }
}

resource "aws_networkfirewall_logging_configuration" "fwlogging" {
  for_each            = toset(var.az_zones)
  firewall_arn = aws_networkfirewall_firewall.firewall[each.key].arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.fw_log_group_flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.fw_log_group_alert.name
        
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
  }

resource "aws_route_table" "firewall" {
  for_each = toset(var.az_zones)
  vpc_id   = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
  tags = {
    Name = "${var.name}-Firewall-Route-Table-${each.key}"
  }
}

resource "aws_route_table_association" "firewall" {
  for_each       = toset(var.az_zones)
  route_table_id = aws_route_table.firewall[each.key].id
  subnet_id      = aws_subnet.firewall[each.key].id
}

resource "aws_route_table" "nat" {
  for_each = toset(var.az_zones)
  vpc_id   = aws_vpc.default.id
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = tolist(aws_networkfirewall_firewall.firewall[each.key].firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  }
  tags = {
    Name = "${var.name}-NAT-Route-Table-${each.key}"
  }
}

resource "aws_route_table_association" "nat" {
  for_each       = toset(var.az_zones)
  subnet_id      = aws_subnet.nat[each.key].id
  route_table_id = aws_route_table.nat[each.key].id
}



#################################################################
################ Common Firewall Rules - Start ##################
#################################################################

resource "aws_networkfirewall_rule_group" "fqdn_allow" {
  capacity = 1000
  name     = "fqdn-allow"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = var.rules_type
        target_types         = var.target_types
        targets              = local.yaml_data.domainAllowList
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "fqdn_deny" {
  capacity = 1000
  name     = "fqdn-deny"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "HTTP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "fw_log_group_flow" {
  name = "${var.env_name}_/aws/network-firewall/flow"
}

resource "aws_cloudwatch_log_metric_filter" "blockedrequest" {
  name           = "blockedrequest"
  pattern        = "blocked"
  log_group_name = aws_cloudwatch_log_group.fw_log_group_alert.name

  metric_transformation {
    name      = "blockedrequest"
    namespace = "${var.env_name}/firewall"
    value     = "1"
  }
}


resource "aws_cloudwatch_log_group" "fw_log_group_alert" {
  name = "${var.env_name}_/aws/network-firewall/alert"
  }

resource "aws_cloudwatch_metric_alarm" "blocked_alert" {
  alarm_name                = "${var.env_name}-firewall-url-blocked"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "blockedrequest"
  namespace                 = "${var.env_name}/firewall"
  period                    = "60"
  statistic                 = "Minimum"
  threshold                 = "1"
  alarm_description         = "This Alarm is executed when a URL is blocked by the firewall during egress"
  insufficient_data_actions = []
  alarm_actions             =[var.slack_events_sns_hook_arn]
}


####### Common Firewall Rules - end ###############

#############################################################
############ IGW Routing Table Configuration - Start ########
#############################################################

resource "aws_route_table" "igwroutetable" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = var.firewall_cidr_block_aza
    vpc_endpoint_id = tolist(aws_networkfirewall_firewall.firewall["us-west-2a"].firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  }

  route {
    cidr_block = var.nat_cidr_block_aza
    vpc_endpoint_id = tolist(aws_networkfirewall_firewall.firewall["us-west-2a"].firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  }

  route {
    cidr_block = var.firewall_cidr_block_azb
    vpc_endpoint_id = tolist(aws_networkfirewall_firewall.firewall["us-west-2b"].firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  }

  route {
    cidr_block = var.nat_cidr_block_azb
    vpc_endpoint_id = tolist(aws_networkfirewall_firewall.firewall["us-west-2b"].firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  }
  
  tags = {
    Name = "${var.name}-IGW-routing-table-${var.env_name}"
  }
}

resource "aws_route_table_association" "igwgwassociation" {
  gateway_id     = aws_internet_gateway.default.id
  route_table_id = aws_route_table.igwroutetable.id
}
####### Routing Tables Configuration - end ########
