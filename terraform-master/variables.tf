variable "region" { 
    default = "us-west-2" 
}

variable "sandbox_account_id" {
    default = "894947205914"
    description = "Sandbox AWS Account ID"
}

variable "production_account_id" {
    default = "555546682965"
    description = "Production AWS Account ID"
}

variable "production_analytics_account_id" {
    default = ""
    description = "Production Analytics AWS Account ID"
}

variable "sandbox_analytics_account_id" {
    default = ""
    description = "Sanbox Analytics AWS Account ID"
}