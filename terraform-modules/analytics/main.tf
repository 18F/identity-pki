resource "aws_vpc" "analytics_vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "analytics-${var.env_name}-vpc"
  }
}

resource "aws_internet_gateway" "analytics_vpc" {
  vpc_id = "${aws_vpc.analytics_vpc.id}"

  tags {
    Name = "analytics-${var.env_name}-vpc"
  }
}

resource "aws_redshift_parameter_group" "redshift_configuration" {
  name   = "analytics-${var.env_name}-redshift-configuration"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }
}

resource "aws_redshift_cluster" "redshift" {
  cluster_identifier           = "tf-${var.env_name}-redshift-cluster"
  database_name                = "analytics"
  master_username              = "awsuser"
  master_password              = "${var.redshift_master_password}"
  node_type                    = "dc1.large"
  cluster_type                 = "multi-node"
  number_of_nodes              = "${var.num_redshift_nodes}"
  cluster_subnet_group_name    = "${aws_redshift_subnet_group.redshift_subnet_group.name}"
  publicly_accessible          = true
  iam_roles                    = ["${aws_iam_role.redshift_role.arn}"]
  enable_logging               = true
  encrypted                    = true
  cluster_parameter_group_name = "${aws_redshift_parameter_group.redshift_configuration.name}"
  bucket_name                  = "${aws_s3_bucket.redshift_logs_bucket.id}"

  vpc_security_group_ids = [
    "${aws_security_group.redshift_security_group.id}"
  ]

  iam_roles = [
    "${aws_iam_role.redshift_role.arn}"
  ]
}

resource "aws_vpc_endpoint" "private-s3" {
    vpc_id = "${aws_vpc.analytics_vpc.id}"
    service_name = "com.amazonaws.${var.region}.s3"
    route_table_ids = ["${aws_route_table.analytics_route_table.id}"]
}

resource "aws_subnet" "redshift_subnet" {
  cidr_block        = "${cidrsubnet(aws_vpc.analytics_vpc.cidr_block, 8, 1)}"
  vpc_id            = "${aws_vpc.analytics_vpc.id}"

  tags {
    Name = "redshift-${var.env_name}-subnet"
  }
}

resource "aws_route_table" "analytics_route_table" {
  vpc_id = "${aws_vpc.analytics_vpc.id}"

  route {
    cidr_block = "52.23.63.224/27"
    gateway_id = "${aws_internet_gateway.analytics_vpc.id}"
  }

  route {
    cidr_block = "54.70.204.128/27"
    gateway_id = "${aws_internet_gateway.analytics_vpc.id}"
  }

  route {
    cidr_block = "${lookup(var.jumphost_cidr_block, var.env_name)}"
    gateway_id = "${aws_internet_gateway.analytics_vpc.id}"
  }

  tags {
    Name = "analytics-${var.env_name}-route-table"
  }
}

resource "aws_route_table_association" "analytics_route_table_association1" {
  subnet_id      = "${aws_subnet.redshift_subnet.id}"
  route_table_id = "${aws_route_table.analytics_route_table.id}"
}

resource "aws_route_table_association" "analytics_route_table_association2" {
  subnet_id      = "${aws_subnet.lambda_subnet.id}"
  route_table_id = "${aws_route_table.analytics_route_table.id}"
}

resource "aws_subnet" "lambda_subnet" {
  cidr_block = "${cidrsubnet(aws_vpc.analytics_vpc.cidr_block, 8, 2)}"
  vpc_id     = "${aws_vpc.analytics_vpc.id}"

  tags {
    Name = "lambda-${var.env_name}-subnet"
  }
}

resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "redshift-${var.env_name}-subnet-group"
  subnet_ids = ["${aws_subnet.redshift_subnet.id}"]

  tags {
    environment = "${var.env_name}"
  }
}

resource "aws_security_group" "redshift_security_group" {
  name = "login-redshift-security-group-${var.env_name}"
  description = "allow GSA to get to redshift"
  vpc_id = "${aws_vpc.analytics_vpc.id}"

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "${aws_subnet.lambda_subnet.cidr_block}"
    ]
  }

  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "${aws_subnet.lambda_subnet.cidr_block}"
    ]
  }

# allow quicksight in via its regional public IPs
# ref http://docs.aws.amazon.com/quicksight/latest/user/regions.html
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "52.23.63.224/27",
      "54.70.204.128/27"
    ]
  }

# allow quicksight out via it's regional public IPs
# ref http://docs.aws.amazon.com/quicksight/latest/user/regions.html
  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "52.23.63.224/27",
      "54.70.204.128/27"
    ]
  }

  # allows jumphost to access redshift
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "${lookup(var.jumphost_cidr_block, var.env_name)}"
    ]
  }

  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "${lookup(var.jumphost_cidr_block, var.env_name)}"
    ]
  }

  tags {
    name   = "login-redshift-security-group-${var.env_name}",
  }
}

resource "aws_security_group" "lambda_security_group" {
  name = "login-lambda-security-group-${var.env_name}"
  description = "allow GSA to get to lambda"
  vpc_id = "${aws_vpc.analytics_vpc.id}"

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "${aws_subnet.redshift_subnet.cidr_block}"
    ]
  }

# Allow VPC endpoint to reach S3
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [
      "${aws_vpc_endpoint.private-s3.prefix_list_id}"
    ]
  }

# Allow to reach Redshift
  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "${aws_subnet.redshift_subnet.cidr_block}"
    ]
  }

  tags {
    name   = "login-lambda-security-group-${var.env_name}",
  }
}

resource "aws_s3_bucket" "redshift_export_bucket" {
  bucket = "login-gov-${var.env_name}-analytics"

  tags {
    Name = "login-gov-${var.env_name}-analytics"
  }

  logging {
    target_bucket = "${aws_s3_bucket.redshift_logs_bucket.id}"
    target_prefix = "s3-analytics-${var.env_name}-"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "redshift_logs_bucket" {
  bucket = "login-gov-${var.env_name}-analytics-logs"

  tags {
    Name = "login-gov-${var.env_name}-analytics-logs"
  }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  lifecycle_rule {
    id = "analyticslogexpire"
    prefix = ""
    enabled = true

    expiration {
      days = 60
    }
  }
}

data "aws_iam_policy_document" "bucket_policy_json" {
  statement {
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs/*",
    ]

    principals {
      type = "AWS"
      identifiers = [
                      "${aws_iam_user.redshift_user.arn}",
                      "arn:aws:iam::193672423079:user/logs",
                      "arn:aws:iam::391106570357:user/logs",
                      "arn:aws:iam::262260360010:user/logs",
                      "arn:aws:iam::902366379725:user/logs"
                    ]
    }
  }

  statement {
    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs"
    ]

    principals {
      type = "AWS"
      identifiers = [
                      "${aws_iam_user.redshift_user.arn}",
                      "arn:aws:iam::193672423079:user/logs",
                      "arn:aws:iam::391106570357:user/logs",
                      "arn:aws:iam::262260360010:user/logs",
                      "arn:aws:iam::902366379725:user/logs"
                    ]
    }
  }
}

resource "aws_s3_bucket_policy" "redshift_logs_policy" {
  bucket = "${aws_s3_bucket.redshift_logs_bucket.id}"
  policy = "${data.aws_iam_policy_document.bucket_policy_json.json}"
}

data "aws_iam_policy_document" "redshift_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
                      "ec2.amazonaws.com",
                      "${aws_iam_user.redshift_user.arn}",
                      "arn:aws:iam::902366379725:user/logs"
                    ]
    }
  }
}

resource "aws_iam_role" "redshift_role" {
  name = "tf-redshift-${var.env_name}-iam-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_role" {
  name = "tf-lambda-${var.env_name}-iam-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "tf-lambda-${var.env_name}-policy"
  path        = "/"
  description = "lambda Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*",
        "ec2:Create*",
        "ec2:Delete*",
        "ec2:Update*",
        "ec2:Describe*",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "redshift_s3_policy" {
  name        = "tf-redshift-${var.env_name}-s3-policy"
  path        = "/"
  description = "S3 Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*",
        "s3:*"
      ],
      "Resource": "*"
    },
    {
    "Effect": "Allow",
    "Action": "s3:PutObject",
    "Resource": "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs/*"
    },
    {
    "Effect": "Allow",
    "Action": "s3:GetBucketAcl",
    "Resource": "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs"
  }
  ]
}
EOF
}

resource "aws_iam_user" "redshift_user" {
  name = "tf-redshift-${var.env_name}-user"
}

resource "aws_iam_policy_attachment" "redshift_policy_attachment" {
  name       = "tf-redshift-${var.env_name}-policy-attachment"
  policy_arn = "${aws_iam_policy.redshift_s3_policy.arn}"
  roles      = [
    "${aws_iam_role.redshift_role.name}"
  ]
  users      = [
    "${aws_iam_user.redshift_user.name}"
  ]
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "tf-lambda-${var.env_name}-policy-attachment"
  policy_arn = "${aws_iam_policy.lambda_policy.arn}"
  roles      = [
    "${aws_iam_role.lambda_role.name}"
  ]
}

resource "aws_lambda_function" "analytics_lambda" {
  s3_bucket        = "tf-redshift-bucket-deployments"
  s3_key           = "lambda_${var.analytics_version}_deploy.zip"
  function_name    = "analytics-etl-${var.env_name}"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "function.lambda_handler"
  runtime          = "python3.6"
  timeout          = 300
  memory_size      = 1536

vpc_config {
  subnet_ids = ["${aws_subnet.lambda_subnet.id}"]
  security_group_ids = ["${aws_security_group.lambda_security_group.id}"]
}

 environment {
   variables = {
     env = "${var.env_name}"
     redshift_host = "${aws_redshift_cluster.redshift.endpoint}"
     encryption_key = "${var.kms_key_id}"
   }
 }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.analytics_lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::login-gov-${var.env_name}-logs"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "login-gov-${var.env_name}-logs"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.analytics_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".txt"
  }
}


# ---------------- NACLs ------------------
resource "aws_network_acl" "analytics_redshift" {
  vpc_id = "${aws_vpc.analytics_vpc.id}"
  subnet_ids = ["${aws_subnet.redshift_subnet.id}", "${aws_subnet.lambda_subnet.id}"]

  # allow ephemeral ports out of VPC
  egress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port = 32768
    to_port = 61000
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # allow 443 out of VPC S3 endpoint

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    rule_no = 400
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }

  # let redshift postgres in and out
  ingress {
    from_port = 5439
    to_port = 5439
    protocol = "tcp"
    rule_no = 500
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  egress {
    from_port = 5439
    to_port = 5439
    protocol = "tcp"
    rule_no = 600
    action = "allow"
    cidr_block = "${var.vpc_cidr_block}"
  }

  // Allow Quicksight to access Redshift
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    rule_no = 700
    action = "allow"
    cidr_block = "52.23.63.224/27"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    rule_no = 800
    action = "allow"
    cidr_block = "52.23.63.224/27"
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    rule_no = 900
    action = "allow"
    cidr_block = "54.70.204.128/27"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    rule_no = 1000
    action = "allow"
    cidr_block = "54.70.204.128/27"
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    rule_no = 1100
    action = "allow"
    cidr_block = "${lookup(var.jumphost_cidr_block, var.env_name)}"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    rule_no = 1200
    action = "allow"
    cidr_block = "${lookup(var.jumphost_cidr_block, var.env_name)}"
  }

  tags {
    Name = "${var.name}-analytics_network_acl-${var.env_name}"
  }
}
