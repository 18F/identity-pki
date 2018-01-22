data "aws_ip_ranges" "route53" {
  regions  = ["global"]
  services = ["route53"]
}

resource "aws_elasticache_subnet_group" "idp" {
  name = "${var.name}-idp-cache-${var.env_name}"
  description = "Redis Subnet Group"
  subnet_ids = ["${aws_subnet.db1.id}","${aws_subnet.db2.id}"]
}

resource "aws_internet_gateway" "default" {
  tags {
    client = "${var.client}"
    Name = "${var.name}-gateway-${var.env_name}"
  }
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "default" {
    route_table_id = "${aws_vpc.default.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
}

resource "aws_security_group" "app" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # need ntp to our ntp servers
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["${var.obproxy1_subnet_cidr_block}","${var.obproxy2_subnet_cidr_block}","${var.outbound_subnets}"]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }
  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }

  # github
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}", "${aws_security_group.jenkins.id}" ]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-app-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-app_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "cache" {
  description = "Allow inbound and outbound redis traffic with app subnet in vpc"

  egress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.app.id}",
      "${aws_security_group.idp.id}"
    ]
  }

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.app.id}",
      "${aws_security_group.idp.id}"
    ]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-cache-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-cache_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "chef" {
  description = "Allow inbound chef traffic and whitelisted IPs for SSH"

  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # github
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need ntp outbound
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["${var.obproxy1_subnet_cidr_block}","${var.obproxy2_subnet_cidr_block}","${var.outbound_subnets}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.app.id}",
      "${aws_security_group.elk.id}",
      "${aws_security_group.jenkins.id}",
      "${aws_security_group.jumphost.id}",
      "${aws_security_group.obproxy.id}",
      "${aws_security_group.idp.id}"
    ]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}", "${aws_security_group.jenkins.id}" ]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-chef-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-chef_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "db" {
  description = "Allow inbound and outbound postgresql traffic with app subnet in vpc"

  egress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [
      "${var.app1_subnet_cidr_block}",
      "${var.idp1_subnet_cidr_block}",
      "${var.idp2_subnet_cidr_block}"
    ]
  }

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [
      "${var.app1_subnet_cidr_block}",
      "${var.idp1_subnet_cidr_block}",
      "${var.idp2_subnet_cidr_block}"
    ]
  }

    # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-db-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-db_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "elk" {
  depends_on = ["aws_internet_gateway.default"]
  description = "Allow inbound traffic to ELK from whitelisted IPs for SSH and app security group"

  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # github
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need ntp outbound
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["${var.obproxy1_subnet_cidr_block}","${var.obproxy2_subnet_cidr_block}","${var.outbound_subnets}"]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }
  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}", "${aws_security_group.jenkins.id}" ]
  }

  ingress {
    from_port = 5044
    to_port = 5044
    protocol = "tcp"
    self = true
    cidr_blocks = [
      "${var.admin_subnet_cidr_block}",
      "${var.app1_subnet_cidr_block}",
      "${var.idp1_subnet_cidr_block}",
      "${var.idp2_subnet_cidr_block}",
      "${var.idp3_subnet_cidr_block}",
      "${var.jumphost_subnet_cidr_block}",
      "${var.obproxy1_subnet_cidr_block}",
      "${var.obproxy2_subnet_cidr_block}"
    ]
  }

  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

  ingress {
    from_port = 9200
    to_port = 9300
    protocol = "tcp"
    self = true
  }

  # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-elk-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-elk_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "jenkins" {
  description = "Allow inbound traffic to ELK from whitelisted IPs for SSH and app security group"

  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }
  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }

  # github
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need ntp outbound
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["${var.obproxy1_subnet_cidr_block}","${var.obproxy2_subnet_cidr_block}","${var.outbound_subnets}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}" ]
  }

    # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-jenkins-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-jenkins_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "jumphost" {
  description = "Allow inbound jumphost traffic: whitelisted IPs for SSH"

  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # allow analytics redshift cluster to get into jumphost.
  # 127.0.0.1/32 is used as a meaningless default CIDR block in case
  # var.env_name is not a valid key to the redshift_cidr_block map.
  egress {
    from_port = 5439
    to_port = 5439
    protocol = "tcp"
    cidr_blocks = ["${lookup(var.redshift_cidr_block, var.env_name, "127.0.0.1/32")}"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # need 80/443 to get packages/gems/etc
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # github
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need ntp outbound
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["${var.obproxy1_subnet_cidr_block}","${var.obproxy2_subnet_cidr_block}","${var.outbound_subnets}"]
  }

  # need dns outbound for ACME cert generation stuff
  egress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["${data.aws_ip_ranges.route53.cidr_blocks}","8.8.8.8/32"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.app_sg_ssh_cidr_blocks}"]
  }

  # need this to let jenkins in
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.admin_subnet_cidr_block}"]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-jumphost-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "amazon_netblocks_ssl" {
  description = "Allow outbound traffic to AWS services (non-ec2 hosts) on 443"

  # need to get to s3 and cloudtrail
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.amazon_netblocks}"]
  }
  name = "${var.name}-amazonnetblocksssl-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-awsnetblocksssl_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "amazon_netblocks_http" {
  description = "Allow outbound traffic to AWS services (non-ec2 hosts) on 80"

  # need to get to s3 and cloudtrail
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.amazon_netblocks}"]
  }
  name = "${var.name}-amazonnetblockshttp-${var.env_name}"
  
  tags {
    client = "${var.client}"
    Name = "${var.name}-awsnetblockshttp_security_group-${var.env_name}"
  }
  
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "idp" {
  description = "Allow inbound web traffic and whitelisted IP(s) for SSH"

  # allow outbound to the VPC so that we can get to db/redis/logstash/etc.
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }
  # need to get packages and stuff (conditionally)
  # outbound_subnets can be set to "0.0.0.0/0" to allow access to the internet
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${var.outbound_subnets}"]
  }

  # AAMVA DLDV API, used by worker servers
  egress {
    from_port = 18449
    to_port = 18449
    protocol = "tcp"
    cidr_blocks = ["66.227.17.192/26"]
  }

  # github
  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["192.30.252.0/22"]
  }

  # need ntp outbound
  egress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    cidr_blocks = ["${var.obproxy1_subnet_cidr_block}","${var.obproxy2_subnet_cidr_block}","${var.outbound_subnets}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "${var.alb1_subnet_cidr_block}",
      "${var.alb2_subnet_cidr_block}"
    ]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "${var.alb1_subnet_cidr_block}",
      "${var.alb2_subnet_cidr_block}"
    ]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ "${aws_security_group.jumphost.id}", "${aws_security_group.jenkins.id}" ]
  }

  # allow CI VPC for integration tests
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.ci_sg_ssh_cidr_blocks}"]
  }

  name = "${var.name}-idp-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp_security_group-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "web" {
  description = "Security group for web that allows web traffic from internet"
  vpc_id = "${aws_vpc.default.id}"

  # allow outbound to the VPC so that we can get to the idp hosts
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  name = "${var.name}-web-${var.env_name}"

  tags {
    client = "${var.client}"
    Name = "${var.name}-web_security_group-${var.env_name}"
  }
}

resource "aws_subnet" "app" {
  availability_zone = "${var.region}a"
  cidr_block = "${var.app1_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-app_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "admin" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.admin_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-admin_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "db1" {
  availability_zone = "${var.region}a"
  cidr_block = "${var.db1_subnet_cidr_block}"
  map_public_ip_on_launch = false

  tags {
    client = "${var.client}"
    Name = "${var.name}-db1_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "db2" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.db2_subnet_cidr_block}"
  map_public_ip_on_launch = false

  tags {
    client = "${var.client}"
    Name = "${var.name}-db2_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "jumphost" {
  availability_zone = "${var.region}b"
  cidr_block = "${var.jumphost_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-jumphost_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "idp1" {
  availability_zone = "${var.region}a"
  cidr_block        = "${var.idp1_subnet_cidr_block}"
  depends_on = ["aws_internet_gateway.default"]
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp1_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "idp2" {
  availability_zone = "${var.region}b"
  cidr_block        = "${var.idp2_subnet_cidr_block}"
  depends_on = ["aws_internet_gateway.default"]
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-idp2_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "chef" {
  availability_zone = "${var.region}b"
  cidr_block        = "${var.chef_subnet_cidr_block}"
  depends_on = ["aws_internet_gateway.default"]
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-chef_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "alb1" {
  availability_zone = "${var.region}a"
  cidr_block        = "${var.alb1_subnet_cidr_block}"
  depends_on = ["aws_internet_gateway.default"]
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-alb1_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "alb2" {
  availability_zone = "${var.region}b"
  cidr_block        = "${var.alb2_subnet_cidr_block}"
  depends_on = ["aws_internet_gateway.default"]
  map_public_ip_on_launch = true

  tags {
    client = "${var.client}"
    Name = "${var.name}-alb2_subnet-${var.env_name}"
  }

  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_vpc_endpoint" "private-s3" {
    vpc_id = "${aws_vpc.default.id}"
    service_name = "com.amazonaws.${var.region}.s3"
    route_table_ids = ["${aws_vpc.default.main_route_table_id}"]
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr_block}"
 # main_route_table_id = "${aws_route_table.default.id}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
   client = "${var.client}"
   Name = "${var.name}-vpc-${var.env_name}"
  }
}
