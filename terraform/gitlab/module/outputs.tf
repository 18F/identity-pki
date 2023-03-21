output "env_name" {
  value = var.env_name
}

output "region" {
  value = var.region
}

output "latest_available_ami_id" {
  value = data.aws_ami.base.id
}

output "default_ami_id" {
  value = local.default_base_ami_id
}

output "ami_id_map" {
  value = var.ami_id_map
}