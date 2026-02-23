
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
# TFE landing zone
#  Creates the necessary TFE resources to support Vault backed
#  dynamic credentials, including a project, and variable set
#  for a specific app and environment (e.g. app-123 in dev) to use
#  Vault backed dynamic credentials for AWS.
#----------------------------------------------------------------#
data "tfe_variable_set" "vault_backed_dynamic_credentials" {
  name         = var.tfe_vault_varset_name
  organization = data.tfe_organization.this.name
}

resource "tfe_project" "this" {
  name         = "${var.app_name}-${var.environment}"
  organization = data.tfe_organization.this.name
}

resource "tfe_project_variable_set" "vault_backed_dynamic_credentials" {
  variable_set_id = data.tfe_variable_set.vault_backed_dynamic_credentials.id
  project_id      = tfe_project.this.id
}

# Creates a project level variable set containing the environment variables that workspaces will use to
# authenticate for the specific environment of the App.
resource "tfe_variable_set" "app_env_vault_backed_aws_credentials" {
  name              = "${var.app_name}-${var.environment}-vault-backed-aws-credentials"
  description       = "This variable set contains variables that configure Vault-backed AWS credentials specifically for ${var.app_name} (${var.environment}) workspaces."
  organization      = data.tfe_organization.this.name
  parent_project_id = tfe_project.this.id
}

resource "tfe_project_variable_set" "workspace_variables" {
  variable_set_id = tfe_variable_set.app_env_vault_backed_aws_credentials.id
  project_id      = tfe_project.this.id
}

resource "tfe_variable" "tfe_vault_role" {
  variable_set_id = tfe_variable_set.app_env_vault_backed_aws_credentials.id

  key         = "TFC_VAULT_RUN_ROLE"
  value       = vault_jwt_auth_backend_role.tfe_workspace_aws_reader_role.role_name
  category    = "env"
  description = "The Vault JWT role runs will use to interact with Vault."
}

resource "tfe_variable" "tfc_vault_backed_aws_run_role_arn" {
  variable_set_id = tfe_variable_set.app_env_vault_backed_aws_credentials.id

  key         = "TFC_VAULT_BACKED_AWS_RUN_ROLE_ARN"
  value       = local.aws_iam_role_arn
  category    = "env"
  description = "The AWS IAM Role ARN runs will assume."
}

resource "tfe_variable" "vault_backed_aws_run_vault_role" {
  variable_set_id = tfe_variable_set.app_env_vault_backed_aws_credentials.id

  key         = "TFC_VAULT_BACKED_AWS_RUN_VAULT_ROLE"
  value       = local.vault_aws_secrets_role_name
  category    = "env"
  description = "The role under the AWS secrets engine in Vault runs will use."
}
