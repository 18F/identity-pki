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
      "^/api/graphql.*",
      "^/api/v4/(groups|projects|users)\\.json",
      "^/api/v4/analytics/group_activity/(issues|merge_requests|new_members)_count",
      "^/api/v4/groups/[0-9]+/(invitations|projects|epics/[0-9]+/award_emoji)",
      "^/api/v4/projects/[0-9]+/issues",
      "^/api/v4/projects/[0-9]+/repository/(branches|tags)",
      "^/api/v4/projects/[0-0]+/templates/issues/Feature_Request",
      "^/api/v4/users/[0-9]+(/status)?",
      "^/api/v4/projects/.*/(merge_requests/.*/approve|approval_settings)",
      "(?i)readme.md",
    ]
  }
  
  relaxed_uri_paths = {
    "docauth_image_upload"        = "^/api/verify/images"                              # https://github.com/18F/identity-devops/issues/4092
    "login_form"                  = "^/([a-z]{2}/)?$"                                  # https://github.com/18F/identity-devops/issues/4563
    "password_screening_flow"     = "^/([a-z]{2}/)?verify/enter_password"              # https://github.com/18F/identity-devops/issues/4563
    "OIDC_authorization"          = "^/openid_connect/authorize"                       # https://github.com/18F/identity-devops/issues/4563
    "account_deletion"            = "^/([a-z]{2}/)?account/delete"                     # https://github.com/18F/identity-devops/issues/6127
    "reauthn"                     = "^/([a-z]{2}/)?reauthn"                            # https://github.com/18F/identity-devops/issues/6221
    "capture_password"            = "^/([a-z]{2}/)?login/password"                     # https://github.com/18F/identity-devops/issues/6389
    "reactivate"                  = "^/([a-z]{2}/)?account/reactivate/verify_password" # https://github.com/18F/identity-devops/issues/6389
    "sign_up_password"            = "^/([a-z]{2}/)?sign_up/create_password"            # https://github.com/18F/identity-devops/issues/6576
  }
}
