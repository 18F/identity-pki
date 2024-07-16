resource "aws_ssmincidents_response_plan" "response_plan" {
  for_each = local.teams
  name     = "${each.key}_response_plan"

  display_name = title("${each.key} Response Plan")
  engagements = [
    aws_ssmcontacts_contact.escalation_plan[each.key].arn
  ]
  incident_template {
    title  = "${title(each.key)} Response Plan"
    impact = "5"

    summary = "Alarm summary"
  }


  depends_on = [aws_ssmincidents_replication_set.incident_manager_regions]
}