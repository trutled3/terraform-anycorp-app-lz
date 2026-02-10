# data "vault_auth_backend" "tfe_jwt" {
#   # namespace = var.vault_namespace
#   path = var.vault_jwt_auth_path
# }

#####################################################################
# Per-workspace TFE run policies
#####################################################################
data "vault_policy_document" "aws_secret_auth" {
  for_each = local.workspace_keys
  rule {
    path         = "auth/token/lookup-self"
    capabilities = ["read"]
    description  = "Allow tokens to query themselves"
  }
  rule {
    path         = "auth/token/renew-self"
    capabilities = ["update"]
    description  = "Allow tokens to renew themselves"
  }
  rule {
    path         = "auth/token/revoke-self"
    capabilities = ["update"]
    description  = "Allow tokens to revoke themselves"
  }
  rule {
    path         = "aws/sts/${each.value.workspace_vault_role_name}"
    description  = "Allow to generate credentials from AWS Secrets Engine"
    capabilities = ["read"]
  }
}

resource "vault_policy" "aws_secret_auth" {
  for_each = local.workspace_keys
  name     = each.value.workspace_vault_role_name
  policy   = data.vault_policy_document.aws_secret_auth[each.key].hcl
}

# Creates a role on an AWS Secret Backend for Vault. Roles are used to map credentials to the policies 
# that generated them.
#
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/aws_secret_backend_role
resource "vault_aws_secret_backend_role" "aws_secret_backend_role" {
  for_each = local.workspace_keys
  #   namespace       = var.vault_namespace
  backend         = var.aws_secret_backend_path
  name            = each.value.workspace_vault_role_name
  credential_type = "assumed_role"

  role_arns = [each.value.workspace_vault_run_role_arn]
}

# Creates a role for the AWS Secrets Engine to assume for the sessions it generates. These are the permissions that you will 
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
data "aws_iam_policy_document" "tfe_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.aws_iam_user_arn]
    }
  }
}

resource "aws_iam_role" "tfe_role" {
  for_each           = local.workspace_keys
  name               = "${each.value.workspace_name}-tfe-role"
  assume_role_policy = data.aws_iam_policy_document.tfe_role_assume_role_policy.json
}

data "aws_iam_policy_document" "tfe_role_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "test_policy" {
  for_each = local.workspace_keys
  name     = "demo"
  role     = aws_iam_role.tfe_role[each.key].id
  policy   = data.aws_iam_policy_document.tfe_role_policy.json
}
