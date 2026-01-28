# This is a sample s3 bucket resource to demonstrate that the workspace can authenticate through Vault to AWS.

# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/run/run-environment#environment-variables
variable "TFC_WORKSPACE_NAME" {}

provider "aws" {}

resource "aws_s3_bucket" "example" {
  bucket = "vault-backed-dynamic-creds-example-bucket-${var.TFC_WORKSPACE_NAME}"
}
