/**
*  make AWS account ID available - required for VPC peering 
**/
data "aws_caller_identity" "current" {}

variable "main_route_table_id" {
    description = "Routing table ID in main VPC for adding route to peered analytics VPC"
}
variable "analytics_cidr_block" {
    description = "Analytics VPC CIDR block"
}
variable "analytics_vpc_id" {
    description = "Analytics VPC ID for peer side of connection"
}
variable "main_vpc_id" {
    description = "Main VPC ID for local side of connection"
}
variable "enabled" {
    description = "Whether to create anything in the module. Set to 0 to disable."
    default = 1
}

/**
 *  Establish VPC peering connection between primary/main and secondary(Analytics) VPCs
 **/
resource "aws_vpc_peering_connection" "main_to_analytics" {
    count = "${var.enabled}"

    peer_owner_id = "${data.aws_caller_identity.current.account_id}" # This will be analytics account ID in the future
    peer_vpc_id   = "${var.analytics_vpc_id}"
    vpc_id        = "${var.main_vpc_id}"

    # TODO: change when analytics moves to different account
    auto_accept = true
}

# TODO figure out how to do count zero
# https://github.com/hashicorp/terraform/issues/15333
#output "vpc_peering_connection_id" {
#    value = "${aws_vpc_peering_connection.main_to_analytics.id}"
#}

/**
* Route packets from main to analytics through our VPC peering connection.
**/
resource "aws_route" "analytics_to_prod" {
    count = "${var.enabled}"

    route_table_id            = "${var.main_route_table_id}"
    destination_cidr_block    = "${var.analytics_cidr_block}"
    vpc_peering_connection_id = aws_vpc_peering_connection.main_to_analytics[0].id
}

# TODO: Add NACLs and SGs?
