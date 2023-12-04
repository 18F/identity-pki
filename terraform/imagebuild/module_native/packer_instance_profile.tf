resource "aws_iam_instance_profile" "packer" {
  name = local.packer_instance_profile_name
  role = aws_iam_role.packer.name
}