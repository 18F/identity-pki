provider "external" { version = "~> 1.2" }
provider "null" { version = "~> 2.1.2" }
provider "template" { version = "~> 2.1.2" }

data "aws_caller_identity" "current" {
}
