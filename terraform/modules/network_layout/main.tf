data "local_file" "network_layout" {
  filename = "${path.module}/network_layout.json"
}

output "network_layout" {
  value = jsondecode(data.local_file.network_layout.content
}

