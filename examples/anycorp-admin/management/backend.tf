# Use the TF_TOKEN_app_terraform_io to set a User Token to authenticate with HCP Terraform.

terraform {
  cloud {
    organization = "<my admin org>" # replace this with your admin org

    workspaces {
      project = "Default Project"
      name    = "<my lz workspace>" # replace this with the workspace for this repo
    }
  }
}
