data "external" "version_info" {
  program = ["python2.7", "${path.module}/version_info.py", "--repopath", "${var.version_info_path}"]
}

output "version_info" {
  value = data.external.version_info.result
}

