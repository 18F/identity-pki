variable "contact" {
  type = object({
    name = string
    info = object({
      email = optional(list(string), [])
      sms   = optional(list(string), [])
      voice = optional(list(string), [])
    })
  })
}

resource "aws_ssmcontacts_contact" "personal_contact" {
  alias = replace(var.contact["name"], ".", "_")
  type  = "PERSONAL"
}

resource "aws_ssmcontacts_contact_channel" "email_channel" {
  contact_id = aws_ssmcontacts_contact.personal_contact.arn

  delivery_address {
    simple_address = length(var.contact["info"]["email"]) > 0 ? var.contact["info"]["email"][0] : "${var.contact["name"]}@gsa.gov"
  }

  name = "${replace(var.contact["name"], ".", "_")}_email"
  type = "EMAIL"
}

resource "aws_ssmcontacts_contact_channel" "sms_channel" {
  for_each   = toset(var.contact["info"]["sms"])
  contact_id = aws_ssmcontacts_contact.personal_contact.arn

  delivery_address {
    simple_address = var.contact["info"]["sms"][index(var.contact["info"]["sms"], each.value)]
  }

  name = "${replace(var.contact["name"], ".", "_")}_sms"
  type = "SMS"
}

resource "aws_ssmcontacts_contact_channel" "voice_channel" {
  for_each   = toset(var.contact["info"]["voice"])
  contact_id = aws_ssmcontacts_contact.personal_contact.arn

  delivery_address {
    simple_address = var.contact["info"]["voice"][index(var.contact["info"]["voice"], each.value)]
  }

  name = "${replace(var.contact["name"], ".", "_")}_voice"
  type = "VOICE"
}
