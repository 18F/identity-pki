output "network_layout" {
  value = jsondecode(file("${path.module}/network_layout.json"))
}
