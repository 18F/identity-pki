resource "aws_ssmcontacts_contact" "escalation_plan" {
  for_each = local.teams
  alias    = "${each.key}-escalation-plan"
  type     = "ESCALATION"
}

resource "terraform_data" "on_call_schedule" {
  for_each = local.rotations
  triggers_replace = [
    aws_ssmcontacts_rotation.rotation[each.key].arn
  ]

  provisioner "local-exec" {
    command = "sleep ${index(keys(local.rotations), each.key) * 5}; ${path.module}/on-call-schedule.sh ${each.key} '${each.value["name"]}'"
  }
}

resource "aws_ssmcontacts_rotation" "rotation" {
  for_each    = local.rotations
  contact_ids = [for contact in each.value["members"] : module.contacts[contact].personal_contact_arn]

  name = each.value["name"]

  recurrence {
    number_of_on_calls    = 1
    recurrence_multiplier = 1

    weekly_settings {
      day_of_week = each.value["handoff_day"]
      hand_off_time {
        hour_of_day    = each.value["handoff_hour"]
        minute_of_hour = each.value["handoff_minute"]
      }
    }

    dynamic "shift_coverages" {
      for_each = local.shift_coverages[each.value["shift_coverage"][var.account_name]]
      content {
        map_block_key = shift_coverages.key
        coverage_times {
          start {
            hour_of_day    = shift_coverages.value["start"]["hour_of_day"]
            minute_of_hour = shift_coverages.value["start"]["minute_of_hour"]
          }
          end {
            hour_of_day    = shift_coverages.value["end"]["hour_of_day"]
            minute_of_hour = shift_coverages.value["end"]["minute_of_hour"]
          }
        }
      }

    }
  }

  time_zone_id = "America/New_York"

  depends_on = [aws_ssmincidents_replication_set.incident_manager_regions]

  # To add new users to a rotation or rearrange the order of users:
  # 1. Comment out the following lifecycle block
  # 2. Add the users to the user.yaml file
  # 3. Ensure the order for all rotations start with the current oncaller
  #    OR target the specific rotation(s) changing
  # 4. Run terraform apply

  lifecycle {
    ignore_changes = [
      contact_ids
    ]
  }
}

resource "aws_ssmcontacts_plan" "escalation_plan" {
  for_each   = local.teams
  contact_id = aws_ssmcontacts_contact.escalation_plan[each.key].arn

  stage {
    duration_in_minutes = 5

    target {
      contact_target_info {
        is_essential = true
        contact_id   = "arn:aws:ssm-contacts:${var.region}:${data.aws_caller_identity.current.account_id}:contact/${each.key}_primary"
      }
    }
  }

  stage {
    duration_in_minutes = 10

    target {
      contact_target_info {
        is_essential = true
        contact_id   = "arn:aws:ssm-contacts:${var.region}:${data.aws_caller_identity.current.account_id}:contact/${each.key}_primary"
      }
    }

    target {
      contact_target_info {
        is_essential = true
        contact_id   = "arn:aws:ssm-contacts:${var.region}:${data.aws_caller_identity.current.account_id}:contact/${each.key}_secondary"
      }
    }
  }

  stage {
    duration_in_minutes = 30

    target {
      contact_target_info {
        is_essential = true
        contact_id   = "arn:aws:ssm-contacts:${var.region}:${data.aws_caller_identity.current.account_id}:contact/${each.key}_primary"
      }
    }

    target {
      contact_target_info {
        is_essential = true
        contact_id   = "arn:aws:ssm-contacts:${var.region}:${data.aws_caller_identity.current.account_id}:contact/${each.key}_secondary"
      }
    }

    dynamic "target" {
      for_each = !contains(flatten([for team, rotation in each.value : [for val in rotation : val["shift_coverage"]]]), "business") ? (
      distinct(flatten([for team, rotation in each.value : [for val in rotation : val["members"]]]))) : []
      content {
        contact_target_info {
          is_essential = true
          contact_id   = "arn:aws:ssm-contacts:${var.region}:${data.aws_caller_identity.current.account_id}:contact/${replace(target.value, ".", "_")}"
        }
      }
    }
  }

  stage {
    duration_in_minutes = 0

    target {
      contact_target_info {
        is_essential = true
        contact_id   = "arn:aws:ssm-contacts:${var.region}:${data.aws_caller_identity.current.account_id}:contact/${each.key}_primary"
      }
    }

  }

  depends_on = [
    aws_ssmcontacts_rotation.rotation,
    terraform_data.on_call_schedule
  ]
}