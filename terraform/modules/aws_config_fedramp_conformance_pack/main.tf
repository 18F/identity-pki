resource "aws_config_conformance_pack" "fedramp_moderate" {
  name = "FedRamp-Moderate"

  template_body = file("${path.module}/templates/Operational-Best-Practices-for-FedRAMP.yaml")
}
