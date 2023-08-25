# for allowing use of region-specific providers with module

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
