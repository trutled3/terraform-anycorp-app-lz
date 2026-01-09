# prereqs
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

module "anycorp-app-lz" {
  source  = "./../../.."
  # insert required variables here

  app_name = var.app_name
  environments = var.environments

  # sensible defaults/static config
  vault_jwt_auth_path = local.vault_jwt_auth_path
  tfe_vault_varset_name = local.tfe_vault_varset_name
}