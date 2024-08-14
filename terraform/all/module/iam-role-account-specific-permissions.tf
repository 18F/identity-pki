module "data_warehouse_user_permissions" {
  count  = local.data_warehouse_enabled ? 1 : 0
  source = "../../modules/data_warehouse_human_role_permissions"

  permitted_regions = ["us-west-2"]

  # Todo: Map role references to resources to create terraform graph dependency
  roles = [
    "PowerUser",
    "Analytics"
  ]
}

# Todo: Create an IDP/Core Application Module

# Todo: Create a SecOps module

# Todo: Create a SMS module "etc"
