module "contacts" {
  for_each = local.contacts
  source   = "./contact"

  contact = {
    name = each.key
    info = { for k, v in each.value : k => v if contains(["email", "sms", "voice"], k) }
  }
}


