## Group membersips for IAM users
#
## AppDev
#resource "aws_iam_group_membership" "appdev_members" {
  #name = "appdev_members"
  #users = [
    #aws_iam_user.aaron_chapman.name,
    #aws_iam_user.clinton_troxel.name,
    #aws_iam_user.douglas_price.name,
    #aws_iam_user.jonathan_hooper.name,
    #aws_iam_user.steve_urciuoli.name,
    #aws_iam_user.zachary_margolis.name,
  #]
  #group = aws_iam_group.appdev.name
#}
#
## AppOnCall
#resource "aws_iam_group_membership" "apponcall_members" {
  #name = "apponcall_members"
  #users = [
    #aws_iam_user.aaron_chapman.name,
    #aws_iam_user.jonathan_hooper.name,
    #aws_iam_user.steve_urciuoli.name,
    #aws_iam_user.zachary_margolis.name
  #]
  #group = aws_iam_group.apponcall.name
#}
#
## BizOps
#resource "aws_iam_group_membership" "bizops_members" {
  #name = "bizops_members"
  #users = [
    #aws_iam_user.akhlaq_khan.name,
    #aws_iam_user.christopher_billas.name,
    #aws_iam_user.douglas_price.name,
    #aws_iam_user.likhitha_patha.name,
    #aws_iam_user.silke_dannemann.name,
    #aws_iam_user.thomas_black.name,
#
  #]
  #group = aws_iam_group.bizops.name
#}
#
## DevOps
#resource "aws_iam_group_membership" "devops_members" {
  #name = "devops_members"
  #users = [
    #aws_iam_user.amit_freeman.name,
    #aws_iam_user.brian_crissup.name,
    #aws_iam_user.jonathan_pirro.name,
    #aws_iam_user.justin_grevich.name,
    #aws_iam_user.mike_lloyd.name,
    #aws_iam_user.mossadeq_zia.name,
    #aws_iam_user.paul_hirsch.name,
    #aws_iam_user.stephen_grow.name,
    #aws_iam_user.steven_harms.name,
    #aws_iam_user.timothy_spencer.name,
  #]
  #group = aws_iam_group.devops.name
#}
#
## FinOps
#resource "aws_iam_group_membership" "finops_members" {
  #name = "finops_members"
  #users = [
  #]
  #group = aws_iam_group.finops.name
#}
#
## SecOps
#resource "aws_iam_group_membership" "secops_members" {
  #name = "secops_members"
  #users = [
    #aws_iam_user.brett_mcparland.name,
    #aws_iam_user.mossadeq_zia.name,
    #aws_iam_user.rajat_varuni.name,
    #aws_iam_user.steven_harms.name,
    #aws_iam_user.timothy_spencer.name,
  #]
  #group = aws_iam_group.secops.name
#}
#
## SOC
#resource "aws_iam_group_membership" "soc_members" {
  #name = "soc_members"
  #users = [
    #aws_iam_user.brett_mcparland.name,
    #aws_iam_user.rajat_varuni.name,
  #]
  #group = aws_iam_group.soc.name
#}
#
## KeyMasters  - Not in team.yml
#resource "aws_iam_group_membership" "keymasters_members" {
  #name = "keymasters_members"
  #users = [
    #aws_iam_user.brian_crissup.name,
    #aws_iam_user.jonathan_hooper.name,
    #aws_iam_user.mossadeq_zia.name,
    #aws_iam_user.rajat_varuni.name,
    #aws_iam_user.steve_urciuoli.name,
  #]
  #group = aws_iam_group.keymasters.name
#}
#
