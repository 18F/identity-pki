# VPN for Synack internal pen testing

variable "synack_vpn_enabled" {
  default = 0
  description = "Whether to run the Synack VPN instance"
}

variable "synack_vpn_cidr_block" {
  default = "18.208.122.146/32"
  description = "IP address of the Synack VPN endpoint"
}

variable "synack_vpn_ami_id" {
  default = "ami-0b97eb9fc6ab7be65" # us-west-2
  description = "AMI ID of Synack VPN instance"
}

output "synack_vpn_local_private_ip" {
  description = "Synack VPN instance private IP. Visit this over https tunneling via the jumphost to set up VPN."
  value = "${element(concat(aws_instance.synack_vpn.*.private_ip, list("")), 0)}"
}

resource aws_instance "synack_vpn" {
  count = "${var.synack_vpn_enabled}"

  ami = "${var.synack_vpn_ami_id}"
  subnet_id = "${aws_subnet.publicsubnet1.id}"
  instance_type = "c4.large"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.synack_vpn.id}"]

  key_name = "agbrody@PIV-201704" # TODO remove

  tags {
    Name = "${var.env_name}-synack-vpn-instance"
  }
}

resource aws_security_group "synack_vpn" {
  count = "${var.synack_vpn_enabled}"

  name = "${var.env_name}-synackvpn"
  description = "Group for Synack VPN instances"
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.env_name}-synackvpn"
  }

  # allow ICMP to/from the whole VPC
  ingress {
    protocol  = "icmp"
    from_port = -1
    to_port   = -1
    cidr_blocks = ["${aws_vpc.default.cidr_block}"]
    description = "Allow ICMP from the whole VPC"
  }
  egress {
    protocol  = "icmp"
    from_port = -1
    to_port   = -1
    cidr_blocks = ["${aws_vpc.default.cidr_block}"]
    description = "Allow ICMP to the whole VPC"
  }

  egress {
    protocol  = "icmp"
    from_port = -1
    to_port   = -1
    cidr_blocks = ["${var.synack_vpn_cidr_block}"]
    description = "Allow ICMP to Synack VPN"
  }

  # allow egress access to synack VPN
  egress {
    description = "allow egress to synack VPN"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.synack_vpn_cidr_block}"]
  }
  egress {
    description = "allow egress to synack VPN"
    from_port = 5044
    to_port = 5044
    protocol = "tcp"
    cidr_blocks = ["${var.synack_vpn_cidr_block}"]
  }
  egress {
    description = "allow egress to synack VPN"
    from_port = 1194
    to_port = 1194
    protocol = "udp"
    cidr_blocks = ["${var.synack_vpn_cidr_block}"]
  }

  ingress {
    description = "Allow HTTPS in from jumphost for web interface"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.jumphost.id}"]
  }
}
