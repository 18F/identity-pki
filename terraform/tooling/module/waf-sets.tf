data "github_ip_ranges" "meta" {}

module "waf_sets" {
  source   = "../../modules/waf_sets/"
  app_name = "gitlab"

  privileged_cidr_blocks_v4 = concat(
    var.privileged_cidr_blocks_v4,
    data.github_ip_ranges.meta.hooks_ipv4,
  )
  privileged_cidr_blocks_v6 = var.privileged_cidr_blocks_v6

  restricted_paths = {
    paths = [
      "^/-/graphql-explorer.*",
      "^/admin.*",
      "^/api.*",
    ]
    exclusions = [
      "^/api/v4/analytics/group_activity/(issues|merge_requests|new_members)_count",
      "^/api/v4/users.json",
      "^/api/graphql.*",
      "^/api/v4/projects/[0-9]+/issues/[0-9]+/(related_merge_requests|award_emoji)",
      "^/api/v4/projects/[0-9]+/repository/(branches|tags)",
      "^/api/v4/users/[0-9]+",
      "^/api/v4/users/[0-9]+/status",
    ]
  }
}
