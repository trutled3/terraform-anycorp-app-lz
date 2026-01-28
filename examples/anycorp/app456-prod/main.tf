# This is just a dummy message to look at in TFE to make sure that the run happened.
# If Vault's Azure secrets engine is configured correctly, this App could use the azurerm provider to talk to Azure using the dynamic credentials
# provided to its workspace runs by TFE

# This is a sample s3 bucket resource to demonstrate that the workspace can authenticate through Vault to AWS.

# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/run/run-environment#environment-variables
variable "TFC_WORKSPACE_NAME" {}

resource "aws_s3_bucket" "example" {
  bucket = "vault-backed-dynamic-creds-example-bucket-${var.TFC_WORKSPACE_NAME}"

  tags = {
    TFE_WORKSPACE = var.TFC_WORKSPACE_NAME
    Environment   = "Prod"
  }
}
