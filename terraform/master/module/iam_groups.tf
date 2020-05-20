module "devops_group" {
  source = "github.com/18F/identity-terraform//iam_assumegroup?ref=7216bbba9a74eee84adf2dabae51a3d8c0d165d5"
  #source = "../../../../identity-terraform/iam_assumegroup"
  
  module_depends_on = [
    module.assume_roles_prod.role_arns,
    module.assume_roles_nonprod.role_arns,
    module.assume_roles_master.role_arns,
  ]

  group_name = "login-devops"
  group_members = [
    aws_iam_user.amit_freeman.name,
    aws_iam_user.brian_crissup.name,
    aws_iam_user.jonathan_pirro.name,
    aws_iam_user.justin_grevich.name,
    aws_iam_user.mike_lloyd.name,
    aws_iam_user.mossadeq_zia.name,
    aws_iam_user.paul_hirsch.name,
    aws_iam_user.stephen_grow.name,
    aws_iam_user.steven_harms.name,
    aws_iam_user.timothy_spencer.name,
  ]
  assume_role_policy_arns = [
    lookup(module.assume_roles_prod.role_arns, "FullAdministrator", ""),
    lookup(module.assume_roles_nonprod.role_arns, "FullAdministrator", ""),
    lookup(module.assume_roles_master.role_arns, "FullAdministrator", ""),
  ]
}
