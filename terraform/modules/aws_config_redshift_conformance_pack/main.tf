resource "aws_config_conformance_pack" "redshift" {
  name = "Redshift"

  template_body = file("${path.module}/templates/Security-Best-Practices-for-Redshift.yaml")
}
