terraform {
  required_version = "~> 1.7"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.71.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "5.6.0"
    }
  }
}

data "tfe_organizations" "this" {}

data "tfe_organization" "this" {
  name = data.tfe_organizations.this.names[0]

  lifecycle {
    precondition {
      condition     = length(data.tfe_organizations.this.names) == 1
      error_message = "Expected exactly one TFE organization for this token, but found ${length(data.tfe_organizations.this.names)}."
    }
  }
}



#----------------------------------------------------------------#
# App Specific Variables for Vault Backed Dynamic Credentials
#----------------------------------------------------------------#
resource "tfe_variable_set" "vault_varset" {
  name         = "${var.app_name}-vault-backed-credentials"
  organization = data.tfe_organization.this.name
}

resource "tfe_project_variable_set" "vault_varset" {
  project_id      = tfe_project.project.id
  variable_set_id = tfe_variable_set.vault_varset.id
}

resource "tfe_variable" "vault_backed_aws_mount_path" {
  variable_set_id = tfe_variable_set.vault_varset.id

  key      = "TFC_VAULT_BACKED_AWS_MOUNT_PATH"
  value    = "true"
  category = "env"

  description = "The AWS secrets engine in Vault to target for credentials."
}

resource "tfe_variable" "vault_backed_aws_run_vault_role" {
  variable_set_id = tfe_variable_set.vault_varset.id

  key      = "TFC_VAULT_BACKED_AWS_RUN_VAULT_ROLE"
  value    = vault_aws_secret_backend_role.aws_secret_backend_role.name
  category = "env"

  description = "The AWS secrets engine in Vault to target for credentials."
}

#----------------------------------------------------------------#
# TFE landing zone
#----------------------------------------------------------------#
resource "tfe_project" "project" {
  name         = "${var.app_name}-project"
  organization = data.tfe_organization.this.name
}

resource "tfe_workspace" "workspace" {
  for_each = toset(var.environments)

  organization = data.tfe_organization.this.name
  project_id   = tfe_project.project.id
  name         = "${var.app_name}-${each.key}-workspace"
}

resource "tfe_variable" "tfe_vault_role" {
  for_each = local.workspace_keys

  workspace_id = each.value.workspace_id

  key      = "TFC_VAULT_RUN_ROLE"
  value    = each.value.workspace_vault_role_name
  category = "env"

  description = "The Vault role runs will use to authenticate."
}


# Vault landing zone

# App Policies
# resource "vault_policy" "secrets_reader" {
#   name = "secrets-reader"

#   policy = <<EOT
# # Configure the actual secrets the token should have access to

# # Example Azure dynamic creds role
# # (NOTE) the Azure creds themselves have more access within Azure (e.g. the ability to create infra)
# # this is just the capabilities that the app has to interact with Vault. All it needs is to be able to read Azure dynamic credentials
# path "azure/creds/${var.app_name}" {
#   capabilities = ["read"]
# }

# EOT
# }

# Creates a role for the jwt auth backend and uses bound claims
# to ensure that only the specified Terraform Cloud workspace will
# be able to authenticate to Vault using this role.
#
# App owners can configure their infrastructure workspaces to use Vault-backed dynamic Azure credentials (https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/vault-backed/azure-configuration)
# They just need to specify a role that TFE will use to ask Vault for Azure credentials. This is that role.
#
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role
resource "vault_jwt_auth_backend_role" "tfe_workspace_reader_role" {
  for_each = local.workspace_keys

  backend        = var.vault_jwt_auth_path
  role_name      = "${var.app_name}-tfe-${each.value.workspace_name}-reader-role"
  token_policies = [vault_policy.aws_secret_auth.name]

  bound_audiences   = [local.tfe_vault_audience]
  bound_claims_type = "glob"
  bound_claims = {
    sub = "organization:${data.tfe_organization.this.name}:project:${tfe_project.project.name}:workspace:${each.value.workspace_name}:run_phase:*"
  }
  user_claim = "terraform_full_workspace"
  role_type  = "jwt"
  token_ttl  = 1200
}
