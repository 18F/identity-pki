variable "region" {
    description = "Region to create the secrets bucket in"
    default = "us-west-2"
}

variable "bucket_name_prefix" {
    description = "Base name for the secrets bucket to create"
}

variable "log_prefix" {
    description = "Prefix inside the bucket where access logs will go"
    default = "logs"
}

# This is optional to support the use case where multiple loadbalancers use the
# same S3 bucket with different log prefixes.
variable "use_prefix_for_permissions" {
    description = "Scope load balancer permissions by log_prefix"
    default = false
}

variable "force_destroy" {
    default = false
    description = "Allow destroy even if bucket contains objects"
}
