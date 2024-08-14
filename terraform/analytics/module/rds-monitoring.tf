# This role is created by the RDS wizard when you enable enhanced monitoring on
# an RDS DB instance. It's just a role to wrap the AWS managed policy
# "AmazonRDSEnhancedMonitoringRole".
resource "aws_iam_role" "rds-monitoring-role" {
  name = "rds-monitoring-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "monitoring.rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "rds-enhanced-monitoring" {
  role       = aws_iam_role.rds-monitoring-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
