resource "aws_config_conformance_pack" "fedramp_moderate" {
  name = "FedRamp-Moderate"

  input_parameter {
    parameter_name  = "CwLoggroupRetentionPeriodCheckParamMinRetentionTime"
    parameter_value = var.cloudwatch_log_group_min_retention
  }

  template_body = file("${path.module}/templates/Operational-Best-Practices-for-FedRAMP.yaml")
}
