variable "region" {
}

variable "sandbox_account_id" {
    description = "Sandbox AWS Account ID"
}

variable "production_account_id" {
    description = "Production AWS Account ID"
}

variable "production_analytics_account_id" {
    default = ""
    description = "Production Analytics AWS Account ID"
}

variable "sandbox_analytics_account_id" {
    default = ""
    description = "Sandbox Analytics AWS Account ID"
}
