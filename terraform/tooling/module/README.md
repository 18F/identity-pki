# Terraform Deployment Pipeline Global Config

This module creates the global config that is required for
deployment pipelines that are created in `../module-pipeline`.  It
sets up the IAM roles, VPC and subnet stuff, network firewall and
NAT gateway, VPC endpoints, etc.
