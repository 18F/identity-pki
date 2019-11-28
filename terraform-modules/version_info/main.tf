data "external" "version_info" {
  program = ["python2.7", "${path.module}/version_info.py"]
}

output "version_info" {
  value = data.external.version_info.result
}

