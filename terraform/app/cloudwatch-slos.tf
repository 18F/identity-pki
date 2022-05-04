module "cloudwatch_sli" {
  source = "github.com/18F/identity-terraform//slo_lambda?ref=9ca808e1cad7add8e7bdccd6aa1199d873d34d54"
  # source = "../../../identity-terraform/slo_lambda"

  env_name          = var.env_name
  load_balancer_arn = aws_alb.idp.arn
  sli_prefix        = "idp"
}
