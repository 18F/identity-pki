# The WAF acts as an ingress firewall for everything in our VPC.
#
# The configuration here does not set up WAF ACLs.  Terraform does not support
# WAF Regional ACLs.  Instead, WAF ACLs are set up manually and shared between
# all environments.  For details, see `../../doc/technical/waf.md`.

# Use the `aws` command-line tool to associate the shared WAF ACL with this
# environment's ALB.  When the associated ALB is destroyed, this association
# is implicitly dropped, so there's no need to explicitly remove it.
resource "null_resource" "associate_idp_acl" {
  depends_on = ["aws_alb.idp"]
  count = "${var.enable_waf ? 1 : 0}"

  # Re-associate whenever the ALB ARN or ACL ID change.
  triggers {
    idp_alb = "${aws_alb.idp.arn}"
    acl_id = "${var.idp_web_acl_id}"
  }

  provisioner "local-exec" {
    command = "aws waf-regional associate-web-acl --web-acl-id ${var.idp_web_acl_id} --resource-arn ${aws_alb.idp.arn}"
  }

  # The following "destroy"-time provisioner is only legal in Terraform 0.9.
  # Uncomment the following when we retire 0.8.  Until then, the Terraform
  # configuration will not properly handle changing var.enable_waf from true
  # to false, but it will properly handle an ALB destroy/recreation.
  # You can remove associations by hand at
  # https://console.aws.amazon.com/waf/home?region=us-west-2#/webacls/rules/eb5d2b12-a361-4fa0-88f2-8f632f6a9819
  #
  #provisioner "local-exec" {
  #  when = "destroy"
  #  command = "aws waf-regional disassociate-web-acl --resource-arn ${aws_alb.idp.arn}"
  #
  #  # If var.enable_waf is true, this provisioner is being run because the
  #  # IDP ALB changed.  It's not strictly necessary to disassociate the web
  #  # ACL from the ALB; this is done implicitly when the ALB is removed, so
  #  # we don't care if this fails.
  #  #
  #  # If var.enable_waf is false, this provisioner is being run because of
  #  # this change.  It's more important that the provisioner fail here so that
  #  # we don't end up running with a web ACL still attached to an ALB
  #  # improperly.  If you encounter problems as a result of this, an easy fix
  #  # is just to taint aws_alb.idp.
  #  on_failure = "${var.enable_waf ? "continue" : "fail"}"
  #}
}
