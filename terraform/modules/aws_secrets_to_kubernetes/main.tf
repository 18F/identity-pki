# Fetching from Secrets Manager
data "aws_secretsmanager_secret" "secret" {
  for_each = { for k, v in var.key_list : k => v if v.source == "secrets-manager" }
  name     = each.key
}

data "aws_secretsmanager_secret_version" "secret" {
  for_each  = data.aws_secretsmanager_secret.secret
  secret_id = each.value.id
}

# Fetching from S3
# Make sure the S3 object is uploaded to the bucket with a content type of text/* or application/json
# Otherwise the content of the object is null https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_object
data "aws_s3_object" "s3_object" {
  for_each = { for k, v in var.key_list : k => v if v.source == "s3" }
  bucket   = each.value.metadata["s3_bucket"]
  key      = each.value.metadata["s3_key"]
}

# Construct our data sections, so we can dynamically name the secrets key
locals {
  secret_data = {
    for key, value in var.key_list : key => merge(
      value.data,
      {
        for k in [value.secretKeyName] : k => value.source == "s3"
        ? data.aws_s3_object.s3_object[key].body
        : jsondecode(data.aws_secretsmanager_secret_version.secret[key].secret_string)[value.metadata.secrets_manager_key]
      }
    )
  }
}

resource "kubernetes_secret" "argocd_repo_secrets" {
  for_each = var.key_list

  metadata {
    name        = each.value.metadata.name
    namespace   = each.value.metadata.namespace
    labels      = lookup(each.value.metadata, "labels", {})
    annotations = lookup(each.value.metadata, "annotations", {})
  }

  data = local.secret_data[each.key]
}