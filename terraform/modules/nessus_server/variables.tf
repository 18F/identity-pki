locals {
  chunked_ipv6 = { for index, chunk in chunklist(
    data.aws_ip_ranges.ec2.ipv6_cidr_blocks, 120
  ) : index => chunk }
  chunked_ipv4 = { for index, chunk in chunklist(
    data.aws_ip_ranges.ec2.cidr_blocks, 120
  ) : index => chunk }
}

variable "rds_db_port" {
  type        = number
  description = "Database port number"
  default     = 5432
}
