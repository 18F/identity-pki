resource "aws_config_config_rule" "approved-amis-by-tag" {
  depends_on       = [aws_config_configuration_recorder.default]
  name             = "approved-amis-by-tag"
  description      = "Checks whether running instances are using specified AMIs. Specify the tags that identify the AMIs. Running instances with AMIs that don't have at least one of the specified tags are noncompliant."
  input_parameters = <<EOP
        {
        "amisByTagKeyAndValue" : "OS_Version:Ubuntu 20.04"
        }
    EOP
  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance"
    ]
  }
  source {
    owner             = "AWS"
    source_identifier = "APPROVED_AMIS_BY_TAG"
  }
}

module "aws_config_fedramp_moderate_compliance" {
  source = "../../modules/aws_config_fedramp_conformance_pack"

  depends_on = [
    aws_config_configuration_recorder.default
  ]
}
