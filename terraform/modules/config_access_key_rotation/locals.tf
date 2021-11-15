locals {
  accesskeyrotation_name_iam = replace(var.config_access_key_rotation_name, "/[^a-zA-Z0-9 ]/", "")
}