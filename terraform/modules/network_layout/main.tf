data "external" "network_layout" {
  program = ["python", "${path.module}/network_layout.py"]
}

output "network_layout" {
  value = data.external.network_layout.result
}

