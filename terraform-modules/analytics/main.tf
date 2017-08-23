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
    cidr_block = "0.0.0.0/0"
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "${aws_subnet.lambda_subnet.cidr_block}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "${aws_subnet.lambda_subnet.cidr_block}"
    ]
  }

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "52.23.63.224/27",
      "54.70.204.128/27"
    ]
  }

  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "52.23.63.224/27",
      "54.70.204.128/27"
    ]
  }

  tags {
    name   = "login-redshift-security-group-${var.env_name}",
    client = "MB18FIX019988"
  }
}

resource "aws_security_group" "lambda_security_group" {
  name = "login-lambda-security-group-${var.env_name}"
  description = "allow GSA to get to lambda"
  vpc_id = "${aws_vpc.analytics_vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags {
    name   = "login-lambda-security-group-${var.env_name}",
    client = "MB18FIX019988"
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

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "bucket_policy_json" {
  statement {
    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs/*",
      "arn:aws:s3:::login-gov-${var.env_name}-analytics-logs"
    ]

    principals {
      type = "AWS"
      identifiers = [
                      "${aws_iam_user.redshift_user.arn}",
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
  s3_bucket        = "tf-redshift-bucket-${var.env_name}-deployments"
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

resource "aws_cloudwatch_event_rule" "every_thirty_minutes" {
    name = "${var.env_name}-every-thirty-minutes"
    description = "Fires every thirty minutes"
    schedule_expression = "rate(30 minutes)"
}

resource "aws_cloudwatch_event_target" "cloudwatch_notification" {
    rule = "${aws_cloudwatch_event_rule.every_thirty_minutes.name}"
    target_id = "analytics_lambda"
    arn = "${aws_lambda_function.analytics_lambda.arn}"
}

resource "aws_lambda_permission" "allow_execution_from_cloudwatch" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.analytics_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_thirty_minutes.arn}"
}
