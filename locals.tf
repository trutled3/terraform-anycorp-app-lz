locals {
  tfe_vault_audience = "vault.workload.identity"

  workspace_keys = {
    for k, w in tfe_workspace.workspace :
    k => {
      workspace_name               = w.name
      workspace_id                 = w.id
      workspace_vault_role_name    = "${w.name}-tfe-role"
      workspace_vault_run_role_arn = "arn:aws:iam::${var.aws_account_id}:role/tfe-${w.name}-role"
    }
  }
}
