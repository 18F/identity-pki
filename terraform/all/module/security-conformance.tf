module "config_fedramp_conformance" {
  source = "github.com/18F/identity-terraform//config_fedramp_conformance?ref=91eadab865ca59a2998387681ca83ac401b7c352"
  #source = "../../../../identity-terraform/config_fedramp_conformance"
  depends_on                  = [aws_config_configuration_recorder.default]
}
