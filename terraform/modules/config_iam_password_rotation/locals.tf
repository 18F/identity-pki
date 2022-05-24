locals {
  passwordrotation_name_iam = replace(var.config_password_rotation_name, "/[^a-zA-Z0-9 ]/", "")
}